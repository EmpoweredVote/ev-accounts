You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-growth-and-development/labels/coder-3.json. Write JSON only, matching
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

politician_id: 9a60d603-194d-410f-ae01-85bd6293f1a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Steve Hilton — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: growth-and-development
topic_id: fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4  served_revision_id: 65e8ffd5-5aac-4d40-8862-a321949eafa4
Question: How should government manage population growth and new development?
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


## Sources

---
snapshot_id: 5448dd45-2738-557d-bca1-5e87edfc5d48
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: b9f0b645-52fe-5909-b32a-9fd633d5a06a
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cut-californias-water-bills

Saved from https://stevehiltonforgovernor.com/policies/cut-californias-water-bills (rendered page text, built-in browser, 2026-10-07) POLICY CUT CALIFORNIA'S WATER BILLS IN HALF BY ENDING MAN-MADE WATER SCARCITY ← POLICY ARCHIVE CUT CALIFORNIA'S WATER BILLS IN HALF BY ENDING MAN-MADE WATER SCARCITY A Califordable plan for abundant, clean, affordable water. THE PROBLEM California has some of the highest water bills in America. A 2026 state-by-state comparison put California fifth highest in the country at $81 per month. The average across the 50 states was about $45. Steve Hilton’s goal is to cut the typical California water bill in half, from $81 to roughly $40 a month. California does not lack water, money, technology or engineering talent. We have winter storms, Sierra snowpack, rivers, reservoirs, groundwater basins, coastal runoff and an entire Pacific Ocean on our doorstep. The problem is that Sacramento has spent decades managing scarcity instead of building abundance. Californians are paying more and getting less. The State Water Resources Control Board’s 2026 Needs Assessment found 406 failing public water systems serving 645,279 people. Another 654 systems serving nearly 1.8 million people are at risk of failing. Hundreds of thousands of Californians are paying for water that does not consistently meet basic health and safety standards. That is what decades of political failure look like. HOW WE GOT HERE Much of California’s water infrastructure was built for a state of about 20 million people. California now has nearly 40 million, but the system has not kept up. Sacramento’s answer has been to tell everyone to use less. Conservation has a role, but it is not a substitute for capturing water when it rains, storing it for dry years, moving it where it is needed and building new supplies. Scarcity drives up bills. Agencies buy more expensive water. Families use less but still have to cover fixed system costs. Projects delayed for decades become far more expensive. Aging pipes and treatment plants deteriorate until repairs cost even more. The state has also failed to make full use of the technology we already have. Modern weather forecasting can give reservoir operators much better information about incoming storms and runoff. Instead of relying on outdated assumptions, California should be using those forecasts to safely hold more water when conditions allow. More reliable surface water can lower costs in another way. In communities dependent on poor-quality or contaminated groundwater, treatment can be expensive. Expanding access to high-quality surface water can reduce that burden while improving the water families actually receive. California studies, delays and litigates projects everyone knows we need. Ratepayers are left with the bill. STEVE HILTON’S PLAN Steve Hilton will end California’s policy of managed water scarcity and build a system that delivers more water at a lower cost. INVEST IN WATER SUPPLY AND LOWER BILLS Steve will dedicate two percent of the state General Fund to water affordability and infrastructure, with no tax increase. It will be paid for by cutting waste and ineffective spending elsewhere in the bloated state budget. The money will go toward projects that reduce long-term costs, including stormwater capture, groundwater recharge, aquifer storage, wastewater recycling, leak reduction, treatment upgrades and new storage. USE BETTER FORECASTING TO CAPTURE MORE WATER California should be using the best weather technology available to operate its reservoirs. Steve will expand Forecast-Informed Reservoir Operations, using improved storm and runoff forecasts to help reservoir managers capture more water when it is safe to do so while maintaining flood protection. This is not some futuristic technology. We can do more of it now. BUILD THE PROJECTS CALIFORNIA HAS DELAYED Steve will remove state barriers and work with federal and local partners to: Raise Shasta Dam by 18.5 feet, adding roughly 634,000 acre-feet of storage. Complete Sites Reservoir, adding 1.5 million acre-feet of off-stream storage. Finish the Folsom South Canal, where only about 27 of the planned 69 miles were built. Remove sediment from critical Sacramento-San Joaquin Delta channels to restore their previous depth and capacity, improve flood conveyance and move water more reliably to farms and communities. Steve will push the Army Corps of Engineers, Bureau of Reclamation and U.S. Geological Survey to move the Delta work forward using existing expedited authorities and in compliance with environmental law. The proposal sent to the campaign specifically calls for targeted sediment removal to restore previously existing channel capacity rather than a new expansion of the Delta system. Together, these projects would capture more water in wet years, store it for dry years, recharge depleted groundwater and improve the system that moves water around California. MAKE DESALINATION AFFORDABLE California has 840 miles of coastline. Seawater desalination should be part of the answer, especially for coastal Southern California. The usual argument is that desalination simply takes too much energy. But California Energy Commission research comparing Los Angeles County supplies found that State Water Project water requires about 3,650 kilowatt-hours per acre-foot, compared with about 3,910 for seawater desalination. They are in roughly the same range. The bigger problem is what California makes projects cost. Large desalination plants overseas have been built for a fraction of the capital cost per unit of capacity of proposed California plants. Steve will streamline permitting and cut unnecessary regulatory and construction costs so California can build desalination at internationally competitive prices. We should not be importing water hundreds of miles across mountains while making it nearly impossible to produce new water along our own coast. STOP THE ENDLESS DELAYS Steve will use his appointments, agency authority, budget powers and existing infrastructure-streamlining laws to accelerate qualifying water projects. He will also push broader reforms so storage, treatment, recycling, recharge and repair projects do not spend decades trapped in bureaucracy and litigation. California does not need another generation of water studies. It needs water. FIX FAILING SYSTEMS FIRST Steve will prioritize failing and at-risk systems for emergency repairs, treatment upgrades, pipe replacement, leak reduction, grants and low-interest financing. Where local communities support it, smaller systems will be consolidated so families are not forced to carry unreasonable costs on their own. Safe drinking water is a basic responsibility of government. California should be able to provide it. SHOW FAMILIES WHERE THEIR MONEY GOES Steve will require plain-English water bills showing the cost of debt, state mandates, litigation, imported water, infrastructure and regulatory compliance. If government decisions are driving up the bill, Californians deserve to see it. WHAT THIS MEANS Steve’s goal is clear: cut the typical California water bill from $81 to roughly $40 a month. That means capturing more of the water California already gets, building the storage and conveyance projects politicians have delayed, using modern forecasting to manage reservoirs better, expanding desalination, fixing failing systems and cutting the enormous cost of getting anything built in California. California has the water. It has the technology and the expertise. What it needs is a governor who will actually build. ← Back to all policies

---
snapshot_id: 01e00e32-20df-5613-9321-bb1bd3c4361b
source_kind: own-site (the person's own site or account)
url: https://goldentogether.com/wp-content/uploads/2024/10/GT_Sustainable-Suburbs-4.pdf

Universal Housing Affordability Housing affordability is the foundation of the California Dream. It is the prerequisite for equal opportunity, quality of life, and economic growth. Here’s how to get it back. Prepared by Golden Together, a Movement to Restore the California Dream Foreword What happened to the California Dream? Home ownership was at the heart of it but now we have the highest housing costs and lowest home ownership in America. It’s almost impossible for regular working Californians to get on the housing ladder, and rents are crippling for many individuals and families, contributing not just to California’s shocking poverty rate (the highest in the nation), but of course our escalating homelessness crisis too. Housing costs are the number one reason people are leaving California, an exodus that has already cost us representation in the Congress for the first time in our state’s history, with further declines projected before the end of the decade. Our Housing Crisis is not only a disaster in its own right: it underlies so many of the other problems we face. Essential services like schools and hospitals can’t recruit the best professionals if there is nowhere nearby they can afford to live. Businesses won’t set up operations in California if there’s nowhere nearby for their workforce to live. We will never close the racial wealth gap unless we expand home ownership, the surest path for people to achieve upward mobility and build generational wealth. So we have to turn things around. The good news is that California’s Housing Crisis is not some natural disaster or unavoidable accident. It is the direct result of policy choices, many of them well-intended, that have nevertheless combined over the years to make it almost impossible to build homes on the scale we need. But these policies can be changed. We can change the abuse of environmental regulations artificially restricting the supply of housing. We can change the excessive taxes on house building artificially inflating the price of housing. We can move beyond the outdated ‘Infill Ideology’ that prevents housing being built in the places people want and at the scale we need. Instead of scarcity, we can have abundance. Instead of politicians telling people where and how to live we can move into a new era of Housing Choice and Homeowner Autonomy. We can solve our debilitating housing crisis with a new approach that is modern, sustainable and more human. We must plan for, and achieve, Universal Housing Affordability. This, our second policy report from Golden Together, shows the way. I’d like to thank everyone who helped with this policy paper, especially Golden Together Advisory Board members Gloria Romero, Joel Kotkin and Mason Harrison. We are also thankful for the tremendous advice we received from our friends in the housing industry and housing policy experts including Randall O’Toole, Marc Joffe, Christopher Calton, Robert Lapsley, Mike Kahoe, John Kabateck, and Dan Dunmoyer. Thanks also to California Policy Center senior fellow Edward Ring who is the lead author on this and all our policy papers. Steve Hilton Founder, Golden Together 2 Key Points: ● Only 15 percent of California households can afford to purchase a median priced home in the state. To purchase a home at the median price in California in 2023, a household would have to have an annual income of $221,000. ● California’s median home price of $819,740 has led to the state having the lowest rate of home ownership in America. Only 18 percent of Californians are homeowners. ● California is also the most expensive state in America for renters. To afford the average monthly rent for a two bedroom home, a full time worker would have to earn over $42 per hour. ● According to UC. Berkeley’s Terner Center for Housing Innovation, there have been over one hundred separate pieces of legislation on housing in the last five years. Yet the actual number of new homes being built is going down (excluding a relatively small number of ADUs). ● Between 2010 and 2021, lawsuits filed under the California Environmental Quality Act (CEQA) challenged housing plans that would have allowed more than one million new housing units. ● So-called ‘Impact Fees’ have become a Stealth Tax on housing. Fees per new housing unit of $150,000 to $200,000 are typical. We have even seen reports of fees as high as $300,000 per new apartment unit. ● Eliminating the private right of action under CEQA, and capping Impact Fees, as outlined in the California Homeownership Affordability Act (developed as a Ballot Initiative by Golden Together), would transform the availability and affordability of housing. ● Beyond that, measures outlined in this report focus on taking advantage of the fact that we already have the highest housing density in the nation. There is plenty of room for new housing in California. ● To illustrate the scale of what is possible if we embrace an ambitious approach based on abundance instead of scarcity, simply increasing California’s urban footprint from the current 5 percent of the state’s land to around 6 percent could provide housing for 10 million new residents, all of them living in homes on quarter acre lots (four person households), with an equivalent area set aside for schools, parks, roads, retail and commercial centers. ● Further investigation should also be applied to other aspects of California’s housing framework that artificially reduce housing availability and affordability, for example the role of corporate ownership of housing and the recently passed Proposition 19. ● Capping taxes on housing, changing zoning laws that restrict housing development, and revising well-intentioned environmental protections to better recognize the needs of California’s struggling households would go a long way towards making housing affordable again. ● All of this can be achieved while maintaining California’s climate goals. There are much better ways to reduce carbon emissions than anti-housing policies that deny working families - in particular families of color - the opportunities of upward mobility and the California Dream. 3 ● We will never solve California’s Housing Crisis and achieve Universal Housing Affordability unless we end the war on single family homes. Suburban neighborhoods should be in addition to urban infill; neither should replace the other. By using the latest innovations and technologies, California’s new, 21st century suburban neighborhoods can be designed to be beautiful, and most importantly, sustainable. 4 Introduction Right up until the final decades of the 20th century, California’s allure was simple and beautiful. Move to the Golden State, get a good job, buy a nice house with a yard in a leafy suburb with good schools for the kids, raise a family and live the dream. Millions of people moved here from all across America and the world and thrived. Suburban life was achievable and fulfilling. Anyone willing to work hard could buy their own small piece of paradise. For most Californians today, however, home ownership is out of reach. California has the highest housing costs in the nation. The median price of a single family home in December 2023 was $819,740, up 6 percent compared to $770,490 a year before. The median household income in California in 2022 was $91,905. Put another way, a family with earnings at the midpoint of the income scale in California would have to spend nearly 9 times their annual gross income to buy a mid-priced home. Even when interest rates were at historic lows a few years ago, buying a home in California was a stretch. Borrowing $750,000 via a 30 year, fixed rate 3 percent mortgage loan would have generated annual payments of $38,264 - a prohibitive 42 percent of median household income. But today that rate is up to 7 percent, which generates an annual loan payment of $60,439. On top of that, a homeowner must also pay for property taxes, property insurance, mortgage insurance, special district assessments, and the most expensive utilities in the country. The average buyer of a median priced home in California today would have to pay nearly 100 percent of their gross income merely to “own” a roof over their head. 5 When buying a home is impossible, renting one is the only option. But California is the most expensive state in America for renters. To afford the average two bedroom home rental in California, a full time worker would have to earn over $42 per hour. A study completed in 2023 by the National Low Income Housing Coalition determined that at the minimum wage at that time in California of $15.50 per hour, it would require 2.7 full time jobs to pay rent on the average two bedroom home while also purchasing other basic necessities. No wonder so many families in California are struggling to stay housed. But it hasn’t always been this way. Even as California’s population exploded in the post-war 1950s and 1960s, average home prices here were less than in the rest of the United States. In 1950, adjusting for inflation, a median priced home only cost $121,336. In 1960, in 2023 dollars, it was $154,520. Even by 1970, a median priced home in California in today’s dollars only cost $180,335. These seem like give-away prices today, and back then, people in the rest of the nation took notice. Drawn by a booming economy, great weather, and affordable homes, new residents arrived by the millions. In 1950 the state’s population was 10.7 million, by 1960 it had risen to 15.9 million, and by 1970 it hit 20 million. Life was good. Starting in the 1970s, however, slowly at first but worse with each passing decade, home prices rose faster than the rate of inflation. Much faster. This report will explain the reasons why this happened, and how it can be fixed. How Housing Became Unaffordable in California On January 7, 1976, in his annual State of the State Address, Governor Jerry Brown uttered a phrase that perfectly captured the changing consensus in Sacramento and among California’s elites: “We are entering an era of limits,” he said, “In place of a manifest economic destiny, we face a sober reassessment of new economic realities; and we all have to get used to it. We can't ignore the demands of social and economic justice or the fragile environment on which we all depend. But, in meeting our responsibility, we are now forced to make difficult choices. Freeways, childcare, schools, income assistance, pensions, health programs, prisons, environmental protection – all must compete with one another and be subject to the careful scrutiny of the common purpose we all serve.” These remarks, and the actions to follow, represented a seismic shift in California’s political landscape. Between 1959 and 1967, Jerry Brown’s father, Governor Edmund G. “Pat” Brown expanded the state’s public works projects to build new colleges and universities, freeways and expressways - and the California Water Project, which remains the most extensive system of water storage and distribution 6 in the world. To this day, Californians still benefit from these public assets. Pat Brown, however, was a product of his time. It was an era when Californians welcomed growth. All of that changed, starting in the 1970s. The “era of limits” Jerry Brown talked about was partly economic. The first OPEC oil embargo in 1973 caused shortages of gasoline. The deep recession and double digit inflation during the Carter years shook the confidence of business entrepreneurs and working families. But also emerging in the 1970s was the modern environmentalist movement. It found widespread support among Californians who lived in coastal cities, hemmed in by mountains, where the smog from leaded gasoline created dangerously unhealthy air pollution. It resonated with residents in the San Francisco Bay Area, who mobilized to stop developments from filling in the shallow wetlands of the South Bay to build more homes. But the environmentalist movement has transformed: from what back in the 1970s was a necessary and common sense reaction to air pollution and land development in sensitive areas, into a powerful political lobby that has made significant development of new housing anywhere in California almost impossible. A series of landmark state laws (each of them spawning additional legislation), and endless rulemaking from state agencies, have created an acute housing shortage with devastating consequences that hit the working class, and the poorest and most vulnerable Californians the hardest. Some of the causes of California’s housing shortage are not solely policy driven. Demographic shifts have altered market demand. In particular, millennials, born between 1981 and 1996, are children of America’s baby boom generation, known to demographers as the “pig in the python” because there were so many post-WW2 babies born. Consequently millennials were also born in great numbers in what has been called the “echo boom,” and since 2000 these millennials have come of age and want to start families. To do this they want to purchase suburban homes, for which demand greatly outstrips supply. Even without the demographic phenomenon of millennials boosting demand for homes, there would be a shortage. California’s Legislative Analyst’s Office released a report in 2015 that estimated the magnitude of this shortage, starting around 1980. They write: “Between 1980 and 2010, California’s major metros added about 120,000 new housing units each year. Our analysis suggests that between 190,000 units per year and 230,000 units per year were needed to keep California’s housing cost growth in line with cost escalations elsewhere in the U.S.” 7 Citing this report in a September 2023 Los Angeles Times article, LAO housing expert Brian Uhler stated “A couple of years of population loss is not going to be enough to offset three decades or more of undersupply.” To bring supply into balance with demand, California is roughly 2 million new homes behind. Campaigning for Governor in 2017, Gavin Newsom pledged 3.5 million new homes by 2025. We are nowhere near meeting that target today. What kind of homes are missing? Assessing true market demand and homebuyer preference is distorted by the fact that today in California, nothing is affordable. Buyers and renters are often forced into the path of least resistance, which can put them in apartments when they’d rather own a condominium, or into condominiums when their dream is a detached single family home with a yard. In a less regulated, more affordable market, supply would adapt to meet demand in order to serve a range of choices, from a cozy apartment in a bustling downtown high rise to a ranch house on a spacious lot in a quiet suburb. From this perspective, solving the housing shortage requires policies that are open to all types of housing. By offering Californians the freedom to choose the types of housing that best suits their needs and desired lifestyle, the market itself will drive what types of homes are built. With greater competition between home builders in a less regulated market, fewer buyers will be priced out. Some will choose high density and the amenities of a vibrant downtown culture, and others will find suburban living to be more family friendly. But if California creates a policy framework for individuals and families to have control over their lifestyle choices, the question of what types of homes are missing will answer itself. People from all backgrounds, at every point on the income scale, will have greater control over where and how they choose to live. This is the more human approach that will help us achieve Universal Housing Affordability: Housing Choice and Homeowner Autonomy. Some critics have suggested that the most popular of those choices for families with children, the choice to live in a suburb, has been one conditioned by the legacy of racial injustice; that suburbs are exclusionary enclaves formed by “white flight” from the urban core. And of course it is true that parts of California, in common with so many places in America, bear the scars of horrific racial discrimination when it comes to housing. But a 2021 study by the Heartland Institute reported that over 50 percent of America’s ethnic minorities now live in suburbs, and “account for virtually all of the suburban growth over the past decade.” California, with a K-12 student population that is 56 percent Latino and only 20 percent non-Latino white, is America’s most multi-ethnic state. Increasing California’s housing supply to the point of universal affordability is by definition inclusive zoning. 8 ‘Planners’ vs. Market - Unlocking Innovation The prevailing ‘Infill Ideology’ among policy makers and urban planners in California is that new housing permits should be issued only within existing cities, should exclusively promote high density housing, and whenever possible should be sited adjacent to or within walking distance of mass transit. This approach has been justified as necessary because suburban “sprawl” is unsustainable. But the reasons cited don’t hold up to scrutiny. Urban infill development can and should occur organically and is part of the natural evolution of an expanding city. But a more human approach based on Housing Choice and Homeowner Autonomy would balance infill development with suburban expansion that addresses the actual preferences of Californians. Building outward removes the pressure on urban real estate to absorb all housing demand at the same time as increasing the overall supply of homes, thereby lowering prices. In a September 2023 study “Building the New America,” published by the Urban Reform Institute, the authors lead off with a section entitled “Planners Against the People.” They write: “For generations Americans have voted with their feet—and their dollars—to achieve what has long been called ‘the dream,’ namely, a home of their own, usually in a low- to mid-density community,” but “Over the past half-century, there has been growing pressure from planners and governments to restrict home construction, particularly on the fringes of urban areas.” While preserving California’s beautiful and essential open space, wildlife and diverse ecosytems is a vital priority, this can comfortably co-exist with expanding our development footprint and welcoming even massive new suburban housing development. California is a vast state, covering over 165,000 square miles, with only 8,000 square miles urbanized. A century ago, California’s population was only 4.7 million; today it is nearly 40 million. Over this period, the vast majority of growth was concentrated around the big coastal cities. Meanwhile, California has over 25,000 square miles of ranchland. Building new homes on quarter acre lots, with four person households, and allocating an equivalent amount for schools, parks, roads, retail and commercial areas would in total only consume 2,000 square miles. This could accommodate 10 million new residents. This fact refutes the belief, embodied in the ideology that currently dominates urban planning decisions and state legislation, that the state is running out of room. If California’s population were to increase from 40 million to 50 million, and every one of those additional 10 million people lived in so-called ‘sprawling suburbs’, it would only increase California’s urban footprint from 8,000 to 10,000 square 9 miles, i.e., from 5 percent to 6 percent of all land in the state. There is plenty of room in California for new housing, including in new suburbs - Sustainable Suburbs. The conventional wisdom that suburbs are not sustainable turns out to be a prejudice rather than fact-based reality. Multistory structures use more construction materials per square foot than one and two story wood framed homes. High density districts lack permeable surfaces to absorb runoff. They lack the cooling impact of trees and other landscaping. On the other hand, new Sustainable Suburbs can incorporate green innovations such as narrower, more reflective roads, and cost-effective insulation and heating/cooling systems. With a higher ratio of rooftop to interior square footage than multistory buildings in high density environments, suburban homeowners can more easily install solar panels to generate a higher proportion of their electricity. Suburbs are not intrinsically worse for the environment than higher density areas, certainly not in spacious California. There are much better ways to meet California’s climate goals and reduce carbon emissions than to deny opportunity to poor and working class families seeking the California Dream. These, more modern and more human approaches to climate policy are a key component of Golden Together’s work - reflected, for example, in our first policy report, Modern Forest Management. Planners continue to claim that suburbs cause more per capita greenhouse gas emissions than high density infill. But the assumption that low density housing causes disproportionate emissions is outdated. Jobs are created within suburbs, employers relocate to new suburbs, people work from home…and vehicles are becoming either zero emission or ultra low emission. What cities and suburbs may look like in the future should not be limited by planning biases that are increasingly debunked and contrary to what Californians want. Relaxing the restrictions on suburban development outside of established cities would take away a natural negative consequence: artificially inflated land values within the existing city’s footprint, yet another significant contributing factor to high home prices. Relaxing restrictions on suburban development can also give rise to far more creative uses of space, once the price of developable acreage descends to affordable levels. Low density suburbs can be havens of greenery and wildlife, with the price of parks, greenbelts and wetlands falling below the threshold that today mandates a developer choose - either build homes with big yards, or set aside development acreage for open space, but not both. With constraints on land acquisition for development reduced or removed, you can have it all. New suburbs can also be linked to higher density centers in a metropolitan area with new and emerging 21st century technologies that California should be famous for pioneering. The promise of virtual work and the allure of suburbs, the cost per square foot of high rise space, the decline of brick and mortar retail and the explosion of work-from-home choices may mean California’s cities cannot simply be revived and expanded in exactly the same way that worked in the 20th century. 10 But we can create new spaces and new opportunities in the middle of legacy downtowns by repurposing commercial and residential buildings that are no longer economically viable. There is an optimal synergy that can be found when peripheral suburban development is permitted, allowing downtowns to evolve without the pressure of absorbing 100 percent of California’s population growth. Successfully reinventing California’s downtowns requires embracing a strategy of decentralization. Ironically, downtown real estate may come down enough in value that cities can become even greater cultural magnets, because the so-called “cultural creatives'' will once again be able to afford to live and congregate there. To make it all work, the prevailing ideology restricting state infrastructure policies must also be reversed, to deregulate energy and water development so private companies can afford to build new supply infrastructure. We have an opportunity in California to once again revolutionize our beautiful state, with its incomparable endowment of open space and natural resources, to set an example to the world with extraordinary appeal. With a mindset of abundance not scarcity, with a strategy of Universal Housing Affordability, the possibilities are truly breathtaking. Expect this version of the future to see flying cars, shared cars, urban cores with lower density, and near self-sufficiency in agriculture, energy and waste management. Expect commercial scale indoor agriculture, growing in converted high rises that feature vertical axis wind turbines to supplement conventional energy on a power grid that embraces an all-of-the-above energy strategy. 11 This is the modern, more human urban vision that defies the current orthodoxy. It is needed now more than ever. It will usher in the shared prosperity of Sustainable Suburbs side by side with a metropolitan megaboom, benefiting everyone. The next sections of this report list some of the most significant legislation and policy priorities that have caused California’s housing shortage and high home prices. Following a discussion of these, we offer recommendations to repeal, revise, or mitigate each of them. The California Environmental Quality Act (CEQA) The state law that has been around the longest, and has done the most damage to the housing opportunity in California, is the California Environmental Quality Act, universally known by its serendipitously phonetic acronym “SEE-kwa.” It was passed by the state legislature in 1970, and at that time was the first legislation of its kind in the nation, if not the world. Its original intent was to “inform government decision makers and the public about the potential environmental effects of proposed activities and to prevent significant, avoidable environmental damage.” Over the past half-century, however, CEQA has acquired layers of legislative updates and precedent setting court rulings, warping it into a beast that denies clarity to developers and derails projects. When projects do make it through the CEQA gauntlet, the price of passage adds punitive costs in time and money. Knowing this will happen deters countless investors and developers from even trying to complete a project in the state. When CEQA was originally passed, it wasn’t even intended to affect housing developments. But that was then. According to Dan Dunmoyer, president of the California Building Industry Association, in the 1970s a CEQA report that was only two pages is today going to require over 1,000 pages. For a typical 200 home subdivision project the developer can expect to spend at least $1 million on CEQA reports in a process that will take 2-3 years, and that’s best case. If there is any litigation, those budgets and timelines go out the window. But the tentacles of CEQA intersect with other regulatory beasts. CEQA, in combination with other environmentalist inspired laws, has created a web of regulatory hurdles that are so unclear and so costly that only a small handful of housing developers, government agencies, or civil engineering contractors are big enough to navigate them. Another compounding problem with CEQA (and related laws designed to protect the environment) is that because so many years are required to get approval, by the time the design of a project is approved, it can often become obsolete. 12 One of the biggest problems with CEQA is that it permits private attorneys to file lawsuits. Ostensibly to ensure development projects are in compliance with CEQA guidelines, often these lawsuits are filed by attorneys with other motives. These include a competitor who wants to delay a project that might take customers or buyers away from their own business or project, a labor union engaging in what has become called “greenmail” to exert pressure on a developer to hire union labor, an environmentalist group that opposes development on principle even if it is badly needed housing, and even entrepreneurial attorneys that are just after lucrative settlements. Of these, the most egregious abuse of CEQA’s “Private Right of Action” that has contributed to the crisis of housing affordability in California is the weaponization of lawsuits to extract “Project Labor Agreements.” These typically include elevated labor costs, the forced use of union labor, or both. As we discuss in our recommendations, there are specific remedies to curb these abuses and restore CEQA to what it was originally intended to be: a productive tool to ensure reasonable environmental oversight on development projects. The Global Warming Solutions Act CEQA is only one big part of a consortium of similar regulatory creatures. The Endangered Species Act, the National Environmental Policy Act, the California Global Warming Solutions Act (AB32, passed by the state legislature in 2006), and seemingly infinite laws, executive orders, agency regulations, and court rulings pursuant to these and others, along with CEQA, have combined to make development in California nearly impossible. For example, a relatively recent regulation pursuant to AB 32 is the requirement that any new housing development calculate the projected annual “vehicle miles traveled” (VMT) the residents will generate. Taking effect in 2018, this new analysis must be done in order to determine how much mitigating fees the developer will be assessed in order to fund mass transit or otherwise offset the anticipated greenhouse gas emissions from vehicles owned by residents of a new community. In the meantime, developers whose projects have been mired in the CEQA process since well before 2018 are now required to supplement the portions of their Environmental Impact Report that evaluated traffic impacts based on congestion with a new evaluation that estimates vehicle miles traveled. And while this VMT analysis is meant to supersede the traffic congestion as “the new lens for assessing transportation impacts,” potential congestion remains grounds for third parties to use CEQA to sue developers to stop their projects. 13 Changing the rules in midstream, conflicting rules depending on the agency, an approval process that takes years if not decades, financing that dries up or is driven up to punitive levels, excessive, unreasonable fees, projects that take so long that if and when they finally get the green light, either the market or the technology has left them far behind and they have to start over...For all its virtues, and there are plenty of them, environmentalism taken to extremes has helped destroy the California Dream for pretty much everyone except the rich. Rent Control and Affordable Housing The California Tenant Protection Act, passed in 2019, limits rent increases for all properties built more than 15 years ago that are not covered by local rent control ordinances. It limits rent increases to 5 percent per year (plus inflation), or 10 percent, whichever is lower. It also bans so-called “no-fault" evictions, meaning that landlords have to have a “valid reason” for evicting a tenant. Rent control lowers the value of rental properties, taking away incentives for landlords to improve their properties. It also lowers the incentive for developers to build new rental properties because they know the annual caps may prevent them in the future from charging market rates. Rent control restrictions have contributed to California’s housing shortage, which has caused rents to soar in properties that haven’t yet reached 15 years since they were constructed. Another legislative response to California’s housing shortage and consequent high prices has been a plethora of laws that create, in various ways, incentives for developers to build affordable housing. For example, housing developments are exempt from or qualify for streamlined CEQA review, or they qualify for tax credits, if they allocate a percentage of homes or apartment units to be affordable. In practice this means that qualifying low-income families are able to rent or buy the affordable housing, but the remainder of homes or apartments in the development are priced higher in order for the developer to recoup their costs. In addition, the legislative work-arounds that have been employed in the name of promoting affordable housing have been accompanied by concessions to labor unions that make housing much more expensive to build. 14 Mandates and Incentives for High Density Housing Frequently combined with affordable housing incentives is California’s State Density Bonus Law. Expanded in 2023, it grants regulatory waivers with reduced allocations for parking if a portion of the housing units, typically at least 10 percent, are restricted to low income or otherwise disadvantaged occupants. Qualifying developments may override local zoning ordinances, exceeding the permitted project density by up to 50 percent, and in some cases up to 80 percent. The consequences of these laws are not only to bring up the prices for the residents of the unsubsidized portion of the development, but to direct investments into these high density projects instead of into building more single family dwellings. This exacerbates the shortage of single family dwellings, raising prices. Since, as previously noted, detached homes with yards remain the overwhelming preference for young families, rent control, affordable housing mandates, and high density mandates all combine to make families’ housing options not only more expensive, but to lock them out of the home ownership they most desire. 15 SB 375 and enhanced Urban Growth Boundaries In 2008 the state legislature passed SB 375, which gave the California Air Resources Board (CARB) authority over “sources of greenhouse gas (GHG) emissions, including cars and light trucks.” Based on the claim that low density housing caused longer commutes and hence more greenhouse gas, SB 375 established streamlined CEQA review for projects that are consistent with a regional plan that meets greenhouse gas reduction targets. The practical effect of SB 375 was to make it harder to get permits to build low density housing, and at the same time, to accelerate the establishment of more restrictive so-called “urban growth boundaries areas.” These geographic boundaries used to merely define where cities and counties intended to direct growth of residential, commercial and retail districts. But even prior to SB 375’s passage, urban growth boundaries were no longer just a practical way to coordinate development among adjacent cities and county governments, and assign special districts to pay for infrastructure improvements. In 1963, in response to concern about urban “sprawl,” a desire to protect farmland, and to “encourage the orderly formation of local governmental agencies”, the state legislature required California’s growing counties to form a Local Agency Formation Commission (LAFCOs). These LAFCOs are run by members of city councils and county supervisors and have the authority to designate urban growth boundaries and prevent or approve annexations of unincorporated land by cities. In practice, because these LAFCOs were controlled by elected officials representing existing cities and counties, they had a vested interest in restricting development in order to grow their own tax base through infill and redevelopment. SB 375 took a problem that was already contributing to a shortage of new homes and made it much worse. Urban growth boundaries are now a key variable in constraining the growth of cities, because with higher density built into a given urban service boundary, the easier it becomes for developers to get approval for their projects there. As noted, the consequence of this squeeze is to make land within urban service areas artificially expensive, because it is more likely to get a development permit, further elevating housing costs. Neglected Infrastructure - High Cost of Materials California’s current system of freeways was built between 1958 and 1974. As then Assemblyman Ray Hanes wrote in 2005, “between 1974 and 1982, the years Jerry Brown was governor, California stopped improving its existing freeway system, and made it virtually impossible to plan for new freeways.” Starting with Brown’s first gubernatorial administration, California also canceled remaining water projects in California. The last major reservoir built in California was New Melones, completed in 1978. 16 Lack of major new freeways in a state that has grown from 21.2 million in 1974 to nearly 40 million today obviously causes congestion and inconvenience - and greenhouse gas from all those vehicles idling in traffic. But lack of water has directly exacerbated our housing shortage. In 2002 the state legislature passed SB 221, wherein applicants intending to develop “large subdivisions will be required to produce proof of water availability in the form of a written verification from the applicable public water supplier.” As California has experienced five multi-year droughts since the 1970s, when work essentially stopped on water infrastructure, vast areas of the state are now effectively off limits to new housing developments. If lack of available water prevents housing from being built at all, lack of local lumber makes the homes that are built cost much more. California’s logging industry used to harvest and mill 6 billion board feet per year. Today, thanks to state and federal regulations that have put most publicly administered forests off limits to logging, lumber has to be imported from other parts of the Pacific Northwest and elsewhere. Similar restrictions have reduced access to other critical in-state building materials. Sand and gravel is abundant in California, and is necessary to make concrete and pavement, but it takes decades to get permits (and a gauntlet of litigation) before starting or even expanding a quarry. Because of their weight, transportation costs are significant for sand and gravel, and for this reason they are traditionally sourced close to construction projects. But not in California. With the regulatory and litigious environment here, that, too, increases the cost for homes in the state. And of course, contributes to greenhouse gas emissions via additional, avoidable transportation. Expensive and Protracted Permit Process to Build Homes California has among the highest permit costs and the slowest permit approval times in the United States. While CEQA reporting can slow projects down for years, even individual home building permits in California can take several months. The worst is San Francisco, where it takes over 600 days on average for the city to issue a building permit. In San Jose, a standard plan check and approval takes 40 weeks “if all goes well.” In San Diego, turnaround time is between six months to one year. In Oakland, development planning projects take 12-36 months. While delays in project approval increase financing costs, as developers have to pay interest on construction loans while they await the final building permits, the amount of the fees also drive up prices. 17 Builders not only have to pay the city and county (often both) a direct fee for project approval, but also “impact fees.” As California’s cities and counties redirected operating budgets and bond issuances away from new infrastructure, the costs instead have been passed on to developers - and thereby homeowners and renters. Included in the price of new housing in California today are impact fees assessed to finance the construction of schools, parks, roads, fire and police, environmental impact, and even installation of public art. A 2018 study that evaluated seven California Cities calculated the total cost of permit and impact fees to range between $20,000 and $155,000 per single family home, and between $12,000 and $75,000 per multifamily unit. Overall, they concluded that development fees add between 6 and 18 percent to median home prices in these cities. It is interesting to note that the “single family home” example they researched was at a density of 8.2 homes per acre. Homes with more spacious lots would undoubtedly carry with them even higher development fees. Today, combined Impact Fees of $150,000 to $200,000 per housing unit are typical - with the highest in the state rising to as much as $300,000 per unit. Obviously, this amount is added directly to the cost of the home. Impact Fees have become a Stealth Tax on housing - and a deeply unfair one at that, since they are levied on the next generation seeking to buy a new home rather than existing homeowners. The Path Towards Universal Housing Affordability The starting point on the path towards Universal Housing Affordability is to address the manifest problems created by CEQA and its abuse. It is difficult to overstate how central a role CEQA has played in making housing unaffordable in California. Removing the notorious “Private Right of Action” under CEQA and restricting the ability to file CEQA lawsuits to County District Attorneys or the state Attorney General would eliminate the countless lawsuits filed by activist environmentalist groups, and opportunistic litigators with hidden agendas. This single reform would dramatically reduce the potential for CEQA lawsuits to derail worthy housing development projects, while leaving intact the ability for elected leaders and the people they represent to exercise oversight over new projects and their impact on the environment. As previously noted, the Global Warming Solutions Act of 2006 is another law that has destructively limited development in California. Enacted in 2006 with a goal of reducing greenhouse gas emissions in the state to 1990 levels by 2020, the law has undergone several revisions, each more aggressive than the last. Fundamental to the law as it affects housing is the claim that single family dwellings and suburban “sprawl” cause more greenhouse gas emissions than high density infill. The consequences of this claim are mandates - such as the Vehicle Miles Traveled assessments and fees required with all 18 new housing proposals - that channel new housing to within the footprint of existing urban areas. This artificially inflates land values inside these “urban service boundaries.” But as noted earlier, the claim that low density housing causes disproportionate greenhouse emissions is outdated. Jobs are created within suburbs, and often employers relocate to new suburbs. People work from home. And vehicles are becoming either zero emission or ultra low emission. Restructuring or eliminating rent control and subsidized affordable housing, in particular, the special incentives for high density housing, will free up investment to build housing on the scale we need. Similarly, if laws and special exemptions designed to streamline the approval process were fully extended beyond affordable housing and high density housing, the supply of all types of housing would increase. Investing in infrastructure - water in particular - and lowering the cost of construction materials is critical to increasing the supply of homes and making them affordable, as is expediting the permit process and putting an end to excessive permit fees. Before making more specific recommendations we will consider what else stands in the way of these needed reforms. 19 Overcoming Obstacles to Affordable Housing Successfully returning California to a place where housing is universally affordable requires a rebalancing of environmentalist values with human priorities. Environmentalists may hold every acre of greenfield in sacred esteem, but clearly, if that value were prevalent and determinative in the past, urban civilization would not exist. Cities and suburbs alike, and the infrastructure necessary to supply them with water, energy, transportation, food and waste management, have an inevitable footprint. It isn’t at all clear that concentrating humans in city centers is ecologically preferable, even if the formidable economic obstacles could be overcome. But policies to cordon off and densify California’s cities are not actually being implemented on environmental grounds alone. Special interests, rather than the public interest, also play a part. The anti-housing policies of recent years have created an economic incentive for companies, government agencies, utilities, and investors to favor scarcity. For example, when the supply of land is artificially constrained, property values go up, which increases property tax revenues to existing jurisdictions. Building new cities on raw land redistributes these tax revenues to the new cities. Similarly, when home building is excessively regulated to the point where affordable housing can no longer be profitably constructed and sold at market prices, it creates an incentive for developers to collect billions from the government to build subsidized housing. And if water and energy consumption is rationed, it relieves the obligation of the government to facilitate new investments in water and energy supply infrastructure despite its feasibility and sustainability. Rapidly transitioning to renewable energy increases costs to ratepayers, as not only solar and wind installations, but also battery farms and thousands of miles of new transmission lines are required. The result is that public utilities, which earn profit on a capped percent of revenue, greatly increase their absolute profits because they are selling the same quantity of electricity while passing through to their customers much higher prices. These are some of the misaligned incentives that may explain support for high density. But under scrutiny, densification does not have a significant ecological benefit, and it comes with a costly price both economically and in terms of how it limits opportunity and upward mobility for millions of families. 20 Specific Policy Reforms Actions to be taken by California’s Governor, State Legislature, and State Agencies (1) End the private right of action under the California Environmental Quality Act (CEQA). The original intent of CEQA was to “inform government decision makers and the public about the potential environmental effects of proposed activities and to prevent significant, avoidable environmental damage.” Over the past half-century, however, CEQA has acquired layers of legislative updates and precedent-setting court rulings, warping it into a distortion of its original intent that denies clarity to developers and derails projects. When projects do make it through the CEQA gauntlet, the price of passage adds punitive costs in time and money. Reforming CEQA by restricting the right to file lawsuits to District Attorneys in California’s counties and the State Attorney General would deter what are now countless lawsuits that constitute a significant impediment to housing starts. (2) Require CEQA lawsuits be submitted within 90 days of a project application being received by the permitting agency, with no CEQA lawsuits to be accepted after that deadline expires. (3) Eliminate the VMT (vehicle miles traveled) analysis currently required for all land use project proposals. (4) Limit the number of hearings on a housing project, and require hearings to take place within 30 days of the previous hearing. Today, agencies that don’t want to approve a project but also don’t want to get sued by the developer will ask for project modifications instead of denying the project. The developer may then have the modifications ready within a few weeks, but the next hearing may not be scheduled for another year, and when that hearing arrives, the agency will ask for additional modifications, repeating the delay yet another year. Reducing the time between hearings to 30 days prevents these delaying tactics. (5) Require Impact Fees for any development to be placed in specific Impact Accounts to prevent agencies from using the proceeds for other budget items. If the Impact Fees are not spent, return them to the project developer. (6) If Impact Fees are being charged to housing developers and they are not used within two years, they should be returned to the homeowners, and the property tax basis for the homes should be lowered by the amount of the refunded fees. (7) Once a project permit is granted, no new Impact Fees can be added. (8) Place a cap on all Impact Fees at 3 percent of the construction cost of the housing, and require the agencies to set priorities for the funds. 21 (9) Abolish Local Agency Formation Commissions, and eliminate urban growth boundaries. (10) To fund infrastructure for new cities and new housing developments, permit Municipal Utility Districts to issue tax-exempt bonds to finance roads, water mains, and sewer and wastewater treatment plants. This financing mechanism would enable a more timely and market driven response to demand for housing, and more efficiently coordinate the homebuilder’s plans with a simultaneous construction of the necessary infrastructure. (11) Eliminate the right of cities and counties to subject development applications to discretionary permitting, wherein bureaucrats can deny code-compliant permit applications. If projects are code-compliant, require building permits to be issued automatically. (12) If building codes or environmental regulations are changed, they shall not apply to projects that have already been approved. (13) Building codes and environmental regulations shall not be changed more than once every five years. (14) Revise the California Building Code to make the installation of solar panels, storage batteries, heat pumps, tankless water heaters, and other active energy efficiency systems on new homes optional on the part of the developer. Let the market determine adoption of these innovations. (15) Restore the net metering rate structure that increases the incentive for homeowners to invest in solar panels and batteries. (16) Abolish zoning restrictions that incentivize high density as a condition of a streamlined permit process, and abolish urban service boundaries that render abundant developable land off-limits to new homes and new communities. (17) Restore infrastructure policies that will help increase the availability of housing as well as reduce the ongoing cost to own homes. For example, repealing the laws and regulations that discourage public and privately funded construction of water and energy supply infrastructure. 22 A New Approach to Housing The policies recommended here are designed to create the conditions where the private sector can again build affordable homes while still making a profit. The innovations that have occurred in the past few years as well as those that are just around the corner promise to deliver a future where urban centers and suburbs both experience a spectacular renaissance. If we can loosen the restrictions on land development, as well as the restrictions on development of energy, water and building materials, and if we can significantly reduce the cost and the time required to get building permits, affordable market housing will be just one major dividend of these reforms. We can recreate the optimism and dynamism of California’s ‘Golden Age’ of building in the 1950s and 1960s, while incorporating the enormous innovation we’ve seen since then - creating new cities and upgrading our existing cities and suburbs in positive, sustainable ways that we can only begin to imagine. Californians should be creating new cities, built for the 21st century, offering an opportunity to incorporate the best new technologies and ideas free of restrictions that inhibit innovation. New cities can incorporate everything we’ve learned over the past half-century, to engage in mindful development, with thoughtful urban design that always prioritizes its impact on the human experience. There is plenty of room to build in California while protecting our precious natural heritage. We can give people Housing Choice and Homeowner Autonomy, reviving upward mobility for the working class and restoring the California Dream for everyone. Cities can be revived. New sustainable suburbs can be built - when thoughtfully conceived, they embody the finest aspirations of the Garden City concept, an idealized vision of town planning where people live in healthy, spacious communities in proximity to open space and wildlife. Building new cities in California that meld Garden City ideals with the latest innovations in architecture and sustainability is the antithesis of much-maligned “sprawl”. When it comes to housing and urban development California can break out of its scarcity mindset, building new cities that embrace both new technologies along with a next-generation cultural identity that is both authentic and unique. This is how California can once again realize its potential, a place where people can live well, an example to the rest of the world. 23 24

---
snapshot_id: f86923e0-2ff7-53a6-85be-a84b7e8796bf
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD ← POLICY ARCHIVE MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD THE PROBLEM California should be leading the future of digital finance. Instead, we are driving innovation, investment, and talent out of our state. For decades, California was the best place in the world to build transformative technologies. Today, companies and entrepreneurs are increasingly looking elsewhere because of overregulation, political uncertainty, and rising costs. The global race for leadership in digital assets and blockchain technology is already underway. States like Texas and Wyoming, along with other countries, are competing aggressively for jobs, investment, and innovation. California has every advantage needed to lead, but bad policy decisions are pushing that opportunity away. Digital assets, blockchain networks, and stablecoins are becoming an important part of the future of finance and payments. If California falls behind, America falls behind with it. WHY THIS IS HAPPENING California’s leadership has adopted a “regulate first, figure it out later” approach to innovation. Instead of creating clear rules that encourage responsible growth, policymakers have created uncertainty that drives companies and investment elsewhere. Companies should not have to guess what the rules are before they invest and build here. California has already seen what happens when government makes it too difficult to build, invest, and innovate. We should not repeat those mistakes with one of the most important emerging technologies in the world. THE PLAN 1. CREATE CLEAR RULES FOR DIGITAL ASSETS California should provide transparent and predictable rules for digital asset companies instead of overly broad regulations that create confusion and drive investment elsewhere. California should clean up the Digital Financial Assets Law and ensure state rules complement emerging federal frameworks instead of conflicting with them. 2. PROTECT PARTICIPATION IN THE DIGITAL ECONOMY Californians should be free to securely control their own digital assets and lawfully participate in blockchain networks without unnecessary government interference. California should end its misguided restrictions on staking and allow Californians to participate in lawful staking services. 3. SUPPORT BLOCKCHAIN INNOVATION AND KEEP CRYPTO JOBS IN CALIFORNIA California should be the best place in the world to build crypto companies and blockchain technology. We should lower barriers to building and stop driving companies, investment, and talent to other states and countries. 4. PROTECT CONSUMERS AND CRACK DOWN ON FRAUD Government has a responsibility to aggressively prosecute scams, fraud, and criminal abuse. But enforcement should target bad actors, not crush legitimate innovation and responsible companies. CONCLUSION California became successful because we built the future instead of fearing it. We have the talent, entrepreneurs, and companies needed to lead the world in digital assets and blockchain technology. But leadership requires a governor who supports growth, encourages innovation, and creates clear rules instead of uncertainty and bureaucracy. Instead of driving opportunities away, California should be the place where the future is built. ← Back to all policies

---
snapshot_id: 5239fff1-68a2-5ba0-83c2-d642714c182e
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/califordable-newsoms-vmt-bombshell

Saved from https://stevehiltonforgovernor.com/policies/califordable-newsoms-vmt-bombshell (rendered page text, built-in browser, 2026-10-07) POLICY CALIFORDABLE: NEWSOM’S VMT BOMBSHELL ← POLICY ARCHIVE CALIFORDABLE: NEWSOM’S VMT BOMBSHELL UP TO $1,350 A MONTH FOR 20 YEARS JUST TO BUILD A HOME 1. THE PROBLEM California has made it too expensive to build homes, and now AB 130 makes that problem worse. Signed into law in 2025 by Gavin Newsom, AB 130 was sold as a way to make it easier to build housing. Instead, it adds a new layer of cost through its Vehicle Miles Traveled (VMT) provisions. VMT is a metric the state uses to estimate how much people living in a new development are expected to drive. Under AB 130, if a project is expected to generate more driving, developers must offset that impact. The law creates a new statewide VMT Mitigation Bank , allowing developers to pay into a government-managed fund instead of reducing driving directly. That fund is used to finance state-approved projects like dense housing or transit-oriented development, based on formulas set by regulators. In other words, the state is setting up a system where the cost of building housing is determined by regulatory formulas rather than the market. The key point is this: the amount developers must pay is not fixed in law. It will be determined by state agencies through a complex system of credits, formulas, and guidance. Some estimates suggest these charges could reach $16,200 per year per unit — or up to $1,350 per month for 20 years for a single home or apartment. That is not a minor fee. That is a major new cost layered onto every new home. Those costs don’t disappear. They get passed directly to buyers and renters. Some projects won’t get built at all. The ones that do will cost more. At a time when California should be lowering costs and building more homes, this moves in the opposite direction. 2. THE PROBLEM DEMOCRATS CREATED California Democrats made housing expensive to build in the first place. Restrictive zoning, CEQA abuse, endless permitting delays, and rising compliance costs have choked off supply and driven up prices across the board. People adjusted to that reality. When homes are scarce and expensive, families make tradeoffs. They live where they can afford to live. They commute. They do what they have to do to make it work. Now, instead of fixing the root problem, Democrats are layering on a new system of VMT charges through a state-run mitigation bank that penalizes those choices. This is the same pattern: create a problem through bad policy, ignore the cause, and then impose new costs on the consequences. You cannot make housing affordable by making it more expensive to build. 3. STEVE’S PLAN Steve Hilton will focus on one thing: lowering the cost of building homes and stopping this new VMT scheme from driving prices even higher. 1. END THE WAR ON SINGLE-FAMILY HOMES AND MAKE IT EASIER TO BUILD Make it easier to build the kinds of homes families actually want, including single-family homes, and allow growth in areas that can support it. State government will stop acting as a barrier. Agencies will be directed to move projects forward, cut delays, and stop using regulations to stall or kill housing. 2. SHUT DOWN THE VMT COST SCHEME AT THE SOURCE The size of these charges will be determined by the Office of Land Use and Climate Innovation (LCI) , which is responsible for setting the rules for the VMT Mitigation Bank. Steve will direct LCI to set the cost of VMT credits at zero , effectively eliminating these charges. That means rewriting the formulas and credit system so this program cannot be used to impose new costs on housing. 3. BLOCK AGENCIES FROM TURNING VMT INTO A BLANK CHECK He will direct state agencies, including Caltrans , to revise their guidance so VMT cannot be used to justify excessive mitigation requirements or new fees on housing projects. The rules will make clear that projected driving cannot be used as a blank check to add costs. 4. CONCLUSION California’s housing crisis is the result of policy choices that made it too difficult and too expensive to build homes. AB 130 adds a new layer of cost through a complicated system of VMT credits, mitigation payments, and state-set pricing formulas that will be defined by regulators, not voters or the legislature. Whether this becomes a major new cost on housing will depend on how those rules are written. The solution is clear: lower the cost of building and stop adding new ones. Build more homes. Get government out of the way. California doesn’t need more bureaucratic schemes. It needs fewer barriers, lower costs, and more homes. ← Back to all policies

---
snapshot_id: 107b693c-5d27-584e-b9ee-8da5c12fcd2c
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/office-of-fun-and-freedom

Saved from https://stevehiltonforgovernor.com/policies/office-of-fun-and-freedom (rendered page text, built-in browser, 2026-10-07) POLICY OFFICE OF FUN AND FREEDOM ← POLICY ARCHIVE OFFICE OF FUN AND FREEDOM Steve Hilton’s plan to cut red tape for nightlife, community events, local venues and public spaces THE PROBLEM: CALIFORNIA KILLJOYS HAVE REGULATED THE FUN OUT OF LIFE California should be the most fun place in America. We have incredible weather, beaches, lakes, mountains, parks, food, music and people from every part of the world. Yet the killjoy politicians and bureaucrats who run state and local government too often seem determined to stop anyone from enjoying it. Want to put on a band at a small venue? Get ready for permits covering entertainment, dancing, sound, alcohol and zoning. Want to organize a block party or street festival? You may have to navigate police, fire, health, public works and alcohol approvals. Want to take your dog to the beach, have a family fire or open a neighborhood gathering place? The answer is often no, or not until you have spent months and thousands of dollars proving that your harmless, fun idea should be allowed. California needs tough rules against real harm. Nobody wants alcohol served to minors, unsafe food, wildfires, wildlife damage, drunk driving or sleepless neighborhoods. But instead of targeting those risks, killjoy politicians and bureaucrats have built a maze of blanket bans, duplicative permits and open-ended delays. Big operators can hire lawyers and consultants. Small businesses, musicians, food vendors, nonprofits, families and volunteers simply give up. The result is emptier downtowns, fewer independent venues, fewer community events and a state that feels more closed and more boring. These killjoy politicians and bureaucrats are crushing the soul and spirit of our state. Their anti-human zealotry has regulated the fun and freedom out of life. STEVE’S SOLUTION: THE OFFICE OF FUN AND FREEDOM As governor, Steve Hilton will create the Office of Fun and Freedom (OFF), a small rapid-action team inside the Governor’s Office. It will not be another sprawling department. Its job will be to get rid of rules, not write new ones. In its first 100 days, the office will conduct a Fun and Freedom Audit of state rules affecting nightlife, live entertainment, community events, food pop-ups, public recreation and social spaces. Every agency will have to identify which restrictions are required by law, which prevent a specific harm and which survive only because nobody has bothered to remove them. Steve will send the Legislature a package to repeal or rewrite the worst of them. OFF will also build one online front door for state event permits and require state agencies to coordinate behind the scenes instead of placing that burden on the public, maddeningly sending people from pillar to post. Routine applications will have firm deadlines, with automatic approval when bureaucrats take too long. For city and county permits, OFF will publish simple model rules, offer technical help and tie relevant state grants to one-stop permitting and reasonable timelines. Communities will keep control over local noise, traffic and public safety, but bureaucracy will no longer get an unlimited veto. A public Fun and Freedom Scorecard will show how long permits take, how much they cost and which agencies are holding people up. We will name and shame the killjoy politicians and bureaucrats. OFF will be judged by how many pointless permits it eliminates, how much time and money it saves, and how many venues and events it helps open. TEN WAYS TO BRING THE FUN BACK 1. LET LOCAL COMMUNITIES DECIDE WHEN LAST CALL ENDS California law currently prohibits alcohol sales between 2 a.m. and 6 a.m. Cities should be allowed to create clearly defined late-night zones where qualified venues can serve until 4 a.m. or even later if there is local approval. Each zone would need a plan for security, noise, transit and safe rides home, with public reporting and the power to suspend the privilege if serious problems develop. This is a local community choice, not a statewide mandate. 2. LET BARS AND RESTAURANTS RUN A NORMAL HAPPY HOUR ABC rules ban free drinks, two-for-one offers and all-you-can-drink promotions. Steve will replace the blanket approach with clear time and quantity limits that allow ordinary promotions, including a complimentary drink or a two-for-one offer, while keeping firm rules against unlimited service, serving minors and serving obviously intoxicated patrons. The state can punish overserving without treating every customer and bartender like a child. 3. CREATE ONE PERMIT FOR LIVE MUSIC AND DANCING Small bars, coffee shops and restaurants should not need a stack of overlapping approvals just to host a band or let people dance. A new Small Venue Permit will combine entertainment, dancing, amplified sound and related local reviews into one application with objective rules and a 30-day deadline. Noise, occupancy, fire safety and closing-hour rules will still apply, but applicants will no longer be bounced from office to office. 4. CREATE ONE APPLICATION FOR BLOCK PARTIES AND STREET FESTIVALS A neighborhood organizer should deal with one lead agency, one application, one payment and one deadline. Police, fire, health, alcohol, street and public works officials will coordinate behind the scenes instead of sending volunteers on a scavenger hunt. Repeat events with a clean record will qualify for a simple annual renewal, and small block parties will use a shorter, cheaper form than major festivals. 5. MAKE FOOD POP-UPS SIMPLE At temporary events, food vendors can face separate health permits even when the event itself already needs approval. California will create one umbrella permit for organizers whose vendors meet standard health rules. Low-risk vendors selling prepackaged or approved cottage foods will use a quick notification process, while higher-risk cooking will still get the inspection it needs. The rule should match the risk, not bury every food booth in the same paperwork. Importantly, it will not be allowed to further entrench the menace of street vendors that are destroying brick and mortar businesses. 6. CUT THE RED TAPE FOR WEDDINGS, FUNDRAISERS AND BEER GARDENS ABC currently requires authorization for every catering event, even when the caterer already holds a state permit and has a clean record. Licensed caterers in good standing will be able to register routine events through instant online notice instead of waiting for another approval. Case-by-case review will be reserved for large or high-risk events, street closures and operators with past violations, with a simpler low-cost path for nonprofit fundraisers. 7. OPEN MORE STATE BEACHES TO DOGS State Parks generally prohibit dogs on beaches unless a location makes an exception. Steve will order a beach-by-beach review and open more sections and off-peak hours where dogs can be accommodated without harming wildlife or other visitors. Clear leash, cleanup and seasonal nesting rules can handle most conflicts. Blanket bans should be the last resort. 8. CREATE MORE PLACES FOR BEACH FIRES AND FAMILY COOKOUTS Too many families arrive at the coast to find that beach fires are prohibited even where a managed fire-ring program could work. State Parks will expand designated fire rings and cookout areas where conditions allow, using reservations, approved fuels, cleanup rules and immediate closures during high fire danger or bad air conditions. Safety changes with the weather and the location. The default should not be a permanent no. 9. GIVE ADULTS LEGAL PLACES TO USE LEGAL CANNABIS INDOORS State law now allows locally approved cannabis cafes, yet the legal path is still closed in much of the state. The Office of Fun and Freedom will provide a ready-to-adopt local ordinance and a fast, coordinated permit for age-restricted licensed lounges and cafes, with worker ventilation protections, no alcohol and strict rules against impaired driving. Local communities will still decide whether to participate. Most communities would much prefer indoor public use rather than the increasingly pervasive stench of weed in public places. 10. MAKE IT EASIER TO OPEN A NEIGHBORHOOD GATHERING PLACE Steve will create a Small Gathering Place rule for independent bars, music venues, coffee shops and community spaces opening in existing commercial buildings. Qualifying projects will get one application, one project manager and a 60-day decision, with by-right approval when objective zoning, occupancy, fire, accessibility and noise standards are met. Vacant storefronts should become places where people meet, not monuments to California’s permitting bureaucracy. RESTORING THE REBEL SPIRIT OF CALIFORNIA The Rebel Spirit of Fun and Freedom is part of the soul of California. Yet it’s being crushed by these endless, bossy, killjoy politicians and bureaucrats endlessly micro-managing every aspect of our lives. Leave us alone! Leave us alone to have fun with our friends and family, to be free, to enjoy our beautiful state! It’s time to fight back against the bureaucratic killjoys. OFF will not only make California more human, it will keeps downtowns alive, support independent businesses, give artists and food entrepreneurs a chance, and give people a reason to get out of the house and spend time together instead of being isolated and stuck to screens. California became the world’s iconic magnet for artists, inventors, rebels and misfits because people came here to create, experiment and live freely. As governor, with the Office of Fun and Freedom in the lead, Steve Hilton will restore the rebel spirit of our state. Tell us which stupid, killjoy rules you want OFF to help get rid of: First Name Last Name Email Phone Tell us what you think the Office of Fun and Freedom should take on. If there is a particular rule, restriction or government hassle behind your suggestion, include as much detail as you can. ← Back to all policies

---
snapshot_id: 426e025c-2f29-5b5d-abf1-762b09ca5a0a
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/b793ce44-9344-4309-ad4d-5887f9d044da

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## Housing Affordability (CBS LA) - CA Governor Candidates - OTR page: https://ontherecord.empowered.vote/meetings/b793ce44-9344-4309-ad4d-5887f9d044da - Video: https://www.youtube.com/watch?v=eQZiD8dv7dI - Date on On the Record: 2026-04-12 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [0:08] do you do for those folks? >> Get rid of the regulations, the mainly environmental regulations that are making it more much more expensive to build housing. So the basic cost of building is four or five times as high in California. Number two, we have to end the lawsuits that are making it more expensive to build housing here cuz they make the whole process much longer and drawn out and you have to go to court and fight these lawsuits. That's because of something called CEQA, the California Environmental Quality Act. That's become pretty well known, but what's not known is it's not so much the regulations in CEQA itself, it's the lawsuits from CEQA because CEQA uniquely has something attached to call the private right of action. All right, so that means that anyone can file a lawsuit. 70% of CEQA lawsuits are used to block housing. Most of those lawsuits are filed nothing to do with the environment. That's the pretext. They're filed by the unions, labor unions to extract what they call project labor agreements, which require one or two or often both of these conditions, prevailing wage and what they call skilled and trained labor. Skilled and trained is a union monopoly. Prevailing wage is about two or three times higher than the market rate. That increases the cost of housing. So we've got to deal with that. The other point and and this is the one where I think no one's really focused on this. Even those two big bills that Gavin Newsom just touted as solving the housing crisis. We're going to abolish CEQA for new housing and all this kind of stuff. It only affected what they call infill development. So the housing that is within the current built environment in California. Why? Going back to what I said earlier, it's an ideology. There's this ideology of what they call density that we can't have sprawl They call it sprawl, right? Where you build outwards, the suburbs that California was famous for. They call it sprawl, I call it the California dream. A single family home where you can raise your family with a yard and enjoy the weather. They're against all of that. They say you can only build in the existing urban footprint. What does that mean? The price of land goes up cuz you're restricting the area that you can build in. And so I would get rid of all of that. That is the result of regulation. They call it VMT, vehicle miles traveled. They put these calculations in and they say, "Well, if you build over there, you're going to have more car journeys, vehicle miles traveled, so we're not going to allow you to do that." So we've got to relax that. And they say you've got to have density. We already have the highest density in the country. Barely 5% of our land in California is developed at all. There is plenty of room to build outwards and let people have that California dream of a home of their own. That's

---
snapshot_id: db7aea50-bd73-5cc5-9ca0-13be015c5989
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/stop-the-hidden-tax-on-new-homes

Saved from https://stevehiltonforgovernor.com/policies/stop-the-hidden-tax-on-new-homes (rendered page text, built-in browser, 2026-10-07) POLICY STOP THE HIDDEN TAX ON NEW HOMES: CAP GOVERNMENT FEES AND REGULATORY COSTS AT $50,000 ← POLICY ARCHIVE STOP THE HIDDEN TAX ON NEW HOMES: CAP GOVERNMENT FEES AND REGULATORY COSTS AT $50,000 A plan to save $150,000 on a typical new single-family home OVERVIEW For a long time, a young family in California could start out in life with a small single-family home and a yard. It might need work. It might not be in their first-choice neighborhood. But they could buy it, build a life and move up from there. Now that first step is out of reach for millions of people. California needs to build more homes, and it needs to build the kind of homes young families can actually buy. The National Association of Home Builders estimates that government regulation adds $131,734 to the price of an average new U.S. single-family home in 2026, or 26.4 percent of its price. That includes fees, building-code changes, delays, required studies, zoning restrictions and other government requirements. Here in California, the fee bill alone can exceed $100,000. A 2025 North State BIA study found that fees in the Sacramento region averaged $109,000 for a standard-sized single-family home, before counting the broader costs of code requirements and delays. The California Building Industry Association has also warned that state regulation imposes major costs and delays on homebuilding. Taking that heavier burden into account, Steve's plan uses a working estimate of around $200,000 in total government fees and regulatory costs for a typical new California single-family home. Steve Hilton will cap the combined cost of fees, permits and government mandates at $50,000 per new home, cut the rules and delays that make building so expensive, and open up more places for starter homes. The goal is to cut the estimated $200,000 government burden to $50,000, saving $150,000 on a typical new single-family home. California has room to build. Government needs to let it happen, and cut the cost of building. THE PROBLEM In the second quarter of 2026, only 19 percent of California households could afford a median-priced existing single-family home. A household needed an income of more than $228,000 to buy one. Think about what that means for a teacher, a police officer, a construction worker or a young couple starting a family. They work here. Their parents may live here. Their children should be able to grow up here. Yet buying even a modest home can seem impossible. Part of the problem is that we do not build enough. Another part is what we build. California has made it so difficult and expensive to produce a smaller single-family home that builders are pushed toward bigger, costlier houses. The family looking for its first home is left with fewer choices. HOW WE GOT HERE Before a shovel goes into the ground, a builder can face fees from multiple agencies, costly requirements and an approval process that drags on for years. Eventually those costs reach the buyer. A UC Berkeley study of seven California cities found that development fees alone came to between 6 and 18 percent of the median price of a new home. The study also found that builders often struggled to get a reliable estimate of what they would owe. How is anyone supposed to plan and build an affordable home when the government cannot give them a clear price? Then there is the question of where homes are allowed to go. Sacramento has spent years trying to fit new housing inside existing developed areas while making it harder to create new neighborhoods. We should build within our cities. We should also be able to build the small, single family homes with yards that young families want. STEVE'S PLAN CAP FEES, PERMITS AND GOVERNMENT MANDATES AT $50,000 PER NEW HOME Steve will propose a statewide cap on the combined costs that state and local government add to a new single-family home through development fees, permits and mandatory requirements. The cap will cover both charges paid to agencies and the cost of complying with requirements imposed as a condition of approval. Builders should be able to see the full government cost before committing to a project. Agencies should not be able to evade the cap by renaming a fee or replacing it with a costly mandate. This will require changes in how infrastructure is paid for. Roads, water and other services have real costs. Those costs should be planned for openly, with any charges to future homeowners disclosed before they buy. A lower upfront bill must mean a real reduction in the buyer's overall costs, rather than the same charges appearing later under a different name. The answer cannot be to keep loading an unpredictable bill onto every new home and then wonder why young families cannot afford one. MAKE THE STARTER HOME POSSIBLE AGAIN Steve wants builders to be able to offer smaller single-family homes, including homes around 1,000 square feet, on lots that make sense for a first-time buyer. California should stop piling requirements onto a modest home that make it cost nearly as much to develop as a much larger one. State building rules should be examined for their effect on housing costs while maintaining essential fire, earthquake and construction safety. GIVE BUILDERS AN ANSWER A home that meets the rules should not spend years waiting for permission. Steve will set firm deadlines for decisions on housing applications and end the cycle of repeated hearings and changing demands. Once a project is approved, government should not impose a new set of requirements halfway through. Steve has also proposed changing CEQA so that housing projects cannot be held up by private lawsuits filed under the law. Environmental rules would still apply, with enforcement by district attorneys or the attorney general. That was a central part of the California Homeownership Affordability Act, the ballot initiative Steve proposed in 2023. OPEN UP MORE PLACES TO BUILD California needs homes in existing neighborhoods and new communities. Steve will remove state barriers that prevent communities from planning new neighborhoods where there is a workable plan for water, roads and other services. Families should have the choice of a smaller home with a yard. State government should stop treating that choice as something to be stamped out. A BETTER WAY FORWARD The first home does not need to be a mansion. For many families, a small, single family home and a little yard would change everything. California used to build those homes. We can build them again. ← Back to all policies

---
snapshot_id: 4d886c73-a785-5040-ba41-521b397c654a
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD ← POLICY ARCHIVE KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD THE PROBLEM California leads the world in artificial intelligence today. But decisions being made in Sacramento risk driving this critical industry out of our state. After 16 years of one-party rule, the pattern is clear: more regulation, higher taxes, and greater political control. That approach has already pushed other industries out of California—and now it is being applied to one of the most important technologies of the future. This is not just about jobs or investment. Artificial intelligence is a foundational technology with major national security implications. The global race is happening now, largely between the United States and China. If California weakens its position, America’s leadership is weakened with it. At the same time, California is failing to prepare its own people for the changes AI will bring. Educational outcomes are declining despite increased spending: Only 47% of students meet basic English standards Only 35% meet basic math standards These failures leave millions unprepared for a more technical, fast-changing workforce. California risks pushing out the industries of the future while failing to prepare its workforce to participate in them. WHY THIS IS HAPPENING This problem stems from a governing approach that prioritizes regulation, restriction, and taxation over growth. California policymakers approach new technologies with excessive caution rather than confidence. Instead of supporting innovation, they impose sweeping rules before technologies are fully developed. At the same time, the state has neglected foundational systems: Schools focus on bureaucracy over outcomes Workforce training and vocational pathways are limited There are fewer clear routes into skilled, well-paying jobs AI also depends on physical infrastructure and reliable energy—areas where California has struggled due to high costs, supply constraints, and regulatory delays. THE THREAT California is already seeing the consequences of this approach. Proposed legislation would: Restrict how AI can be developed and used Increase liability under vague standards Add new layers of bureaucracy Examples include: AB 1979: restricting AI use in healthcare SB 420: imposing liability for “algorithmic discrimination” SB 813: creating a new AI regulatory commission These proposals risk slowing innovation, pushing investment elsewhere, and increasing government control over technology. Combined with proposals like taxing unrealized gains, these policies threaten the foundation of California’s startup ecosystem. Unless direction changes, it will become easier for innovators to build the future somewhere else. THE PLAN 1. EXTEND CALIFORNIA’S GLOBAL LEADERSHIP IN AI California must be the best place in the world to build, invest, and grow AI companies. That requires: A strong business climate Affordable infrastructure A well-educated workforce Government should enforce basic accountability—but avoid sweeping, preemptive regulation on evolving technologies. 2. SET CLEAR, COMMON-SENSE GUARDRAILS There are real risks, but solutions should be targeted and practical. Focus areas include: Protecting children Preventing fraud and impersonation Safeguarding intellectual property and identity The approach should: Enforce existing laws Close clear gaps Avoid vague, open-ended rules 3. COMPETE FOR THE FULL STACK OF AI JOBS California must capture the entire AI ecosystem, including: Energy Manufacturing Infrastructure Computing Software and applications Right now, many of these jobs are going elsewhere due to cost and regulatory barriers. Fixing this means: Faster approvals Lower barriers to building A clear commitment to growth 4. DELIVER ABUNDANT ENERGY AND INFRASTRUCTURE AI depends on reliable, affordable energy. California must shift from scarcity to abundance by: Expanding in-state energy production Modernizing the grid Removing barriers to infrastructure development This includes: Utilizing existing natural gas capacity Expanding nuclear power over time Meeting rising electricity demand must be treated as an urgent priority. 5. PREPARE CALIFORNIANS TO WIN IN THE AI ECONOMY The most important role of government is preparing people—not controlling technology. Current education outcomes are failing students and the workforce. Key priorities include: Ensuring literacy and math proficiency Using phonics-based instruction Holding schools accountable for performance Students should not advance without mastering fundamentals. In addition: Expand vocational and technical education Support retraining for displaced workers Change is coming. The goal is to ensure Californians can move forward—not fall behind. CONCLUSION California has all the advantages needed to lead the world in artificial intelligence—but those advantages are being undermined by bad policy decisions. The state faces a choice: Continue down a path of overregulation, high costs, and declining outcomes or Prioritize growth, innovation, and opportunity If California gets this right, it will lead the AI revolution for decades to come . ← Back to all policies

---
snapshot_id: 432809c4-4a12-508f-8b7c-169afab18e02
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policy/bring-back-the-starter-home-in-california/

Bring Back the Starter Home in California - Steve Hilton for Governor Skip to content ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate Bring Back the Starter Home in California Share This A Califordable Plan for First-Time Buyers The Problem California used to be a place where you could get ahead. Work hard, save up, buy your first home, and build a life. That path is disappearing. A generation ago, buying your first home was something many Californians could imagine doing in their 20s. Today, the median first-time homebuyer is 40. Today, first-time buyers are being shut out of the market entirely. The homes that do get built are too big, too expensive, and completely out of reach for young, middle-class families. Starter homes, the foundation of a healthy housing market, have almost vanished. That’s not just a housing issue. It’s an opportunity issue. When there’s no entry point into the market, families can’t get started. Workers can’t afford to stay. And the entire system locks up, with fewer homes available and higher prices across the board. More than half of Californians under 35 say housing costs make them consider leaving the state. California isn’t building the kinds of homes people actually need. And until that changes, affordability will keep getting worse. Why This Is Happening This is the result of years of bad policy under one-party rule. California Democrats have made it harder and more expensive to build at every step of the process. Costs have been layered on without regard for what they do to the final price of a home. Fees, mandates, and requirements are often the same regardless of size, which makes smaller, entry-level homes far less viable to build. When the cost structure looks like that, builders don’t stop building—they shift toward larger, more expensive homes where the numbers still work. At the same time, the approval process has become slower, more complex, and more uncertain. Projects face overlapping requirements and drawn-out timelines that add months or even years before construction begins. Every delay adds cost, and those costs are passed directly on to buyers. California stopped building 1,000-square-foot starter homes and started building 2,000-plus-square-foot houses few young families can afford. When risk is high and costs are unpredictable, builders shift toward projects that can absorb those costs. Starter homes get squeezed out. None of this is accidental. It’s the predictable outcome of years of policy decisions that ignored cost, supply, and basic economics. The Plan 1. Make Starter Homes Profitable to Build If we want more starter homes, we have to make them financially viable. Reduce or defer fees for entry-level homes Align fees with home size instead of flat charges Allow fees to be financed over time instead of paid upfront Eliminate state income tax on profits tied to qualifying starter home construction Builders should not be punished for building the homes young Californians actually want. 2. Fast-Track Starter Home Projects Time kills starter home development. Create a fast-track approval process for projects that include starter homes Set clear, enforceable timelines for approvals Encourage innovative design that builds in flexibility, for example starter homes that can easily add more space to accommodate family expansion If a project meets the rules, it should move quickly. No more endless waiting. 3. Enforce Accountability One of the biggest barriers to starter homes is the lack of follow-through. Establish a Governor’s Housing Expediter to unblock stalled approvals Require adoption of proven best practices for housing development Impose real consequences when projects are delayed or blocked without justification If we’re serious about building more homes, we need to make sure it actually happens. 4. Stop Adding Costs We cannot keep raising costs and expect prices to fall. Implement a five-year freeze on new housing regulations Require cost-benefit review of recent mandates Prevent new layers of requirements that drive up construction costs Before adding more rules, we need to understand what the current ones are doing. 5. Expand Starter Homes in Existing Neighborhoods Starter homes don’t only come from new subdivisions. Expand incentives for building and selling ADUs as entry-level homes Create financing tools to lower upfront costs for buyers Encourage smaller, more affordable units within existing communities This creates new opportunities without starting from scratch. 6. Create a Starter Home Loan Program Young Californians should not need family wealth to buy their first home. Create a state-backed Starter Home Loan Program for first-time buyers purchasing qualifying starter homes Allow assistance for down payments, closing costs, or interest-rate buydowns Structure the program as a deferred second loan, repaid upon sale or refinance Tie the program directly to newly built starter homes to increase supply, not just demand California should make it easier to buy your first home, not just easier to qualify for debt. Conclusion The starter home was the foundation of the California Dream. Today, it’s out of reach. If the next generation can’t buy their first home, they won’t stay. And if they don’t stay, California doesn’t work. We don’t need more excuses or more bureaucracy. We need to build again—starter homes, at scale, at prices young families can actually afford. That’s how you open the door again. That’s how you make our state Califordable again. Share This Related Policies No State Income Tax on Your First $150,000 The Problem California families are getting squeezed from every direction. Housing costs are out of control. Utility bills keep rising. Groceries cost more. Insurance costs more. Child care, gas, and health insurance continue to get more expensive. For too many Californians, it feels harder every year to get ahead. At the same time, the political […] Emergency Election Count Accelerator Plan INTRODUCTION California should be able to conduct elections that are both secure and timely. Every legal ballot should be counted, but voters should not have to wait weeks to find out the outcome of an election. The state routinely mobilizes personnel and resources during emergencies. When election offices face massive post-election backlogs, California should do […] Make California the Crypto Capital of the World The Problem California should be leading the future of digital finance. Instead, we are driving innovation, investment, and talent out of our state. For decades, California was the best place in the world to build transformative technologies. Today, companies and entrepreneurs are increasingly looking elsewhere because of overregulation, political uncertainty, and rising costs. The global […] Rebalancing California’s Carbon Sequestration Strategy A Common-Sense Plan for Natural Carbon Sequestration California’s Climate Policy Is Failing Working People California politicians have spent years making life more expensive in the name of climate policy while failing at one of the most basic environmental responsibilities of all: properly managing California’s forests, watersheds, and natural lands. Working people are paying more for […] Bring Hollywood Home Steve Hilton’s Plan to Revive and Grow California’s Film and Television Industry The Problem California invented the entertainment business. Hollywood became the global center for film and television, supported by world-class talent, crews, studios, and infrastructure. But that advantage is slipping away. Production is leaving California for states and countries offering better incentives, lower costs, […] Keep California the AI Capital of the World The Problem California leads the world in artificial intelligence today. But decisions being made in Sacramento risk driving this critical industry out of our state. After 16 years of one-party rule, the pattern is clear: more regulation, higher taxes, and greater political control. That approach has already pushed other industries out of California—and now it […] Load More Steve Hilton For Governor X-twitter Instagram Facebook Youtube Paid for by Steve Hilton for Governor 2026 By entering your phone number and selecting to opt in, you consent to receive SMS/MMS marketing and polling text messages, donation requests, updates, and other important information to that number from Steve Hilton for Governor. Msg&data rates may apply. Msg frequency varies. Reply HELP for help or STOP to opt-out at any time. SMS information is not rented, sold, or shared. View Privacy Policy and Terms & Conditions. To make a donation by check, please send your contribution to: P.O. Box 730 Hilmar, CA 95324 Press Inquiries ONLY: [email protected] Copyright &copy; 2026. Steve Hilton for Governor. All Rights Reserved Campaign News Contact Privacy Policy