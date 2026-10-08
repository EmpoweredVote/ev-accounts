You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-tariffs/labels/coder-1.json. Write JSON only, matching
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

### topic_key: tariffs
topic_id: 683c8084-2281-4920-a07c-18439b2dd413  served_revision_id: c9b67f92-c9b9-4f7e-a10b-c312a4219346
Question: How should trade policy balance domestic industry with global commerce?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. eliminate all tariffs and pursue completely free trade with every country.
  2. reduce most tariffs, keeping only limited exceptions.
  3. use tariffs selectively to protect key American industries and jobs.
  4. increase tariffs on countries that don't trade fairly with America.
  5. impose high tariffs on all imports to bring manufacturing back to America.

#### Annex

# tariffs — served revision c9b67f92-c9b9-4f7e-a10b-c312a4219346 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`9f094155-…`); coders code the served text below.

**Question:** "How should trade policy balance domestic industry with global commerce?"

**Orientation:** **inverted.** Rung 1 is the **least** government action (no tariffs at all), rung 5
the most (high tariffs on all imports). CLAUDE.md names Tariffs as a ladder that runs the other way
from the corpus convention. The rungs order **how widely and how high tariffs apply**.

**Levels with a lever:** federal. Congress holds the tariff power and has
delegated much of it to the President; members act through trade agreements, tariff bills and votes
to end the emergencies that some tariffs rest on. State and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "tariff", "duty", "import tax", "levy", "free trade", "free-trade agreement" (FTA),
"USMCA", "most-favoured-nation" (MFN), "normal trade relations", "Section 232" (national security),
"Section 301" (unfair practices), "IEEPA" (emergency powers), "reciprocal tariffs", "baseline tariff",
"universal tariff", "de minimis", "dumping", "countervailing duties", "trade deficit", "reshoring".

1. **"eliminate all tariffs and pursue completely free trade with every country."**
   - Means: no tariffs on any import from any country.
   - Operative clauses: [a] eliminate all tariffs; [b] completely free trade with every country.
   - Establishing evidence looks like: own words that reject every tariff, for every country. "All"
     and "every" are absence clauses (V4.2 "Silence is not a clause").
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a **free-trade agreement** removes tariffs. It removes them
     with one partner and keeps others → not [b]; alone → `direction-only` _(proposed)_.

2. **"reduce most tariffs, keeping only limited exceptions."**
   - Means: most tariffs are cut or removed; a small number stay.
   - Operative clauses: [a] reduce most tariffs; [b] keep only limited exceptions.
   - Establishing evidence looks like: own words or an instrument that rolls back tariffs broadly and
     names the few it keeps.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - The exceptions are no longer limited to products that harm the environment. Any limited set of
     exceptions meets [b].
   - Commonly confused with rung 3 because the "limited exceptions" can be key industries. Code 2
     when the passage calls for a **general reduction** of tariffs now in force; code 3 when it
     defends or adds tariffs on named sectors without a general reduction _(proposed)_.

3. **"use tariffs selectively to protect key American industries and jobs."**
   - Means: tariffs are a tool for some strategic industries; they are not a general policy.
   - Operative clauses: [a] selective — named industries or products; [b] to protect domestic
     industries and jobs.
   - Establishing evidence looks like: support for a sector tariff (steel, semiconductors, shipbuilding)
     **plus** something that excludes rungs 4 and 5 (own words against broad or country-wide
     tariffs). One sector tariff alone shows the protective side → `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a sector tariff often targets one country's products. The
     **basis** decides: protecting an industry → 3; answering a country's trade practices → 4
     _(proposed)_.

4. **"increase tariffs on countries that don't trade fairly with America."**
   - Means: raise tariffs on specific countries because of how they trade.
   - Operative clauses: [a] increase tariffs; [b] on countries named as trading unfairly.
   - Establishing evidence looks like: a bill or own words that raise tariffs on a named country for
     dumping, subsidies, currency practices or barriers to U.S. goods.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because "reciprocal" schedules reach nearly every country.
     A uniform baseline tariff on all imports with higher rates for named countries meets "all
     imports"; "high" needs own words or a rate the passage calls high, otherwise `direction-only`
     between rungs 4 and 5 _(ruled 2026-10-01)_.

5. **"impose high tariffs on all imports to bring manufacturing back to America."**
   - Means: a high tariff on everything the country imports, to move manufacturing home.
   - Operative clauses: [a] high; [b] on all imports; [c] to bring manufacturing back.
   - Establishing evidence looks like: own words or an instrument that sets a tariff on all (or
     nearly all) imports and calls it high or sets a rate the passage itself calls high. Clause [c]
     states the purpose; it is not a separate test _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Who sets tariffs.** A bill that requires Congress to approve new tariffs, or that returns tariff
  authority from the President, decides which branch acts, not what the tariff is → `adjacent`, the
  same reasoning as preemption (V2, H12) _(ruled 2026-10-01)_. A vote to end the emergency that a set of tariffs
  rests on is `on-question` (it ends those tariffs) but `direction-only`: one set is not "most
  tariffs" _(ruled 2026-10-01)_.
- **Trade agreements** cut tariffs with partners and keep others → `direction-only` _(proposed)_.
- **Sanctions, export controls and investment screening** are not tariffs → `adjacent`.
- **Trade adjustment aid, tariff-relief payments to farmers, or rebates from tariff revenue** →
  `adjacent` _(proposed)_.
- **Budget, reconciliation and omnibus votes** with a tariff item → V4 `multi-subject`.


## Sources

---
snapshot_id: 6490dc40-9ee0-5853-82e7-fb30788c1de3
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:53] the cut? This race will come down to those who earned it versus those who are trying to buy it. [4:16] >> Kaylin, because Democrats are the ones that aspire to include everyone and not leave anyone behind, like my parents who came with $12 in their pocket to California and they live the California dream. My three sisters and I, we got to live the California dream. But it doesn't come easy. You have to work hard. My mother today still shops with coupons. And you learn that when you watch that growing up. And I know that my job as attorney general, as Secretary of Health and Human Services is always to help people like my parents who are working hard. And that's why I fought for our families, made sure that when Donald Trump was attacking us the first time, we went toe-to-toe with him more than 120 times. I had to sue Donald Trump to keep him from destroying our state of California. When I was Secretary of Health and Human Services, we expanded access to healthcare to more Americans than ever in the history of the country. We were able to negotiate lower drug prices for the first time in history for Medicare and we prove that we can drop prices by up to 80%. If we fight to make California affordable, people will stay and they will come to this great state. [10:00] to that. >> And I hope we I'll get a chance to respond to Mr. Mayan's attack as well. [10:43] >> So, Mr. Mayan chose to divert from answering the question about affordability to launch a tax. What I would simply say to him is let's focus on who's raising the cost of living in California the most. And that's Donald Trump. The price of gas has gone up$1 to2 dollars because of Donald Trump and his war in Iran. The price of goods, groceries have gone up in California because of Donald Trump's illegal tariffs. [11:07] >> but it's [15:20] >> Well, I'm I'm fascinated to to see people argue that we should get rid of the funding for the roads so we can take care of potholes, the the highways so we can make sure that we don't have massive congestion or our transit systems by getting rid of the one way we fund uh those systems the most, the gas tax. If we were to get rid of the Trump gas tax, we would be able to save ourselves about a two one to$2 dollars at least just in the Trump gas tax as a result of his war in Iran. Let's start focusing where the real problem is. And yes, I'm going to repeat Donald Trump as often as I have to because he's the real menace we have in California. [16:44] >> Yeah, it's a rich response from a guy who made his billions investing in fossil fuels, in oil camp companies, in coal companies. Now he makes the billions and he has spent more than every other candidate combined in his campaign using those profits to now try to buy his seat in the governor's office. Tom, the last thing we need is someone who makes riches from investing in oil companies and then accuse everyone else of doing the wrong thing. [25:51] >> Mayor Mayan should take a look at my record and you'll realize that the largest health enterprise in the world, the Department of Health and Human Services is big. It's because we have to make sure we're doing everything to improve the health care for 333 million Americans. And we balanced our budget four years in a row. So, Matt, here's the thing. I've been able to balance budgets much larger than your city of of San Jose and make sure that we continue to improve health care for more and more Americans. But on the issue of taxes, here's here's the point. Everyone should pay their fair share. No one can claim that a CEO who's making more than a thousand times more than their line workers is paying their fair share. And Tom, one of these days we'll let us know how much money you have in the Cayman Islands so we can make sure we tax you [27:20] >> but being able to balance it is an important [27:46] Americans we helped. [27:54] We were able to get more Americans insured than ever and they >> mind if I just finish the point, >> Mr. Mayor. Finish your point and then one at a time. [28:31] career politician time, Secretary Ber. >> Yeah, totally untrue, man. That sounds like a MAGA talking point. Listen, [28:38] it's under the facts. Under my watch, more Americans gain health coverage than ever in the history of the country. More than 300 million. Under my watch, we were able to let give folks access to the Obamacare uh insurance policies on the marketplace for in some cases $10 or less a month in premiums. Today, those are skyrocketing and people are losing those premiums and insurance coverage because Donald Trump abandoned those healthc care subsidies. [29:01] >> Learn the facts, Matt, before you start talking on this. [34:00] can I [34:03] >> So, I'm the only one who actually has experience taking on Trump in the way he's handling undocumented immigrants because when he was president the first time, I was the attorney general and we took him on straight on in court. We stopped him from trying to force local law enforcement to do the bidding of ICE. We were able to make sure we protected the DACA program for our dreamers all the way to the Supreme Court and we beat Donald Trump. What we have to do is make sure that Trump cannot invade California. And you can't stop him if you've got a governor like Steve Hilton who is his dad. Donald Trump's his daddy and he will protect them all the way through. [40:36] I think we should police Donald Trump's masked mercenary force that they call ICE. I think we should prosecute any of the forces that that violate the law. And I think we should jail anyone who has violated the law. That goes all the way to the top. If anyone has violated the laws of California, they should serve time. >> And I'm telling you, no one has. That's, you know, there are two people who are dead in Minneapolis because they were simply doing duty and being able to act. [46:21] >> Well, I served and we helped the state of California when I was at the Department of Health and Human Services, but when I was attorney general, when Trump was president the first time, we took him on. Uh, every time he tried to attack our state, when he tried to force us to do things that were against the law, when he tried to deny us our resources, we took him on. That's why I had to go toe-to-toe with him in court over 120 times. And most of those cases we were able to win. I will tell you this, whether it was on women's health care, whether it was protecting immigrants rights, whether it was defending our environmental laws, we took him on. And because Donald Trump doesn't understand the laws very well, we were able to beat him over and over, including taking the Affordable Care Act all the way to the Supreme Court and defending it. [49:56] >> Alex, let's be clear. I've been consistent for over 30 years. When I was in Congress, I talked about how Medicare for all is probably the most efficient way that we can do healthcare. And I have always been there. I haven't changed. And so those those reports were inaccurate. I continue to be for Medicare for all. And I can show you how I have actually expanded healthcare because those very subsidies that you mentioned are what help us reach record levels of Obamacare coverage. More than 24 and a half million people under our watch were able to get their health insurance coverage. that is now going down because Trump has denied people the chance those to have subsidies. And the Republicans and Mi Mr. Hilton, who has been endorsed by Donald Trump, haven't said whether they would fight to help those Californians regain their coverage. And so, Steve, will you support having those tax subsidies for Obamacare returned to those Californians who are losing their insurance [50:56] singlepayer system in California. >> We we should try to get to a Medicare for all program. And while we are continuing to work in that direction, we should make sure we are expanding coverage because the most important thing we have to do is give give people peace of mind that they can afford their healthcare and that we will continue to give it to more. >> Thank you, sir. Mr. [51:52] >> So a guy who is funding his campaign to a tune of over $150 million with profits made from oil companies from uh helping fund uh private for-profit prisons that are detaining immigrants in California. Has a real short memory span of how to make sure this place works. I continue to enjoy the support of health care sectors throughout California, doctors, nurses. I have I've got the endorsement of nurses as well and I will continue to fight to make sure everyone has access to good quality healthcare in California as I proved it when I was Secretary of Health and Human. [52:48] >> is that a question I [52:50] go ahead >> as I said when I was secretary of health and human services I was is that a yes or no >> I'm answering the question so the the most important thing about having a Medicare for all plan is that it includes includes all everyone for all and what we have to do is get to the point where we are covering everyone with something like Medicare for all. So I am absolutely for Medicare for all and we will get there. We'll build towards it because that's the way you get folks covered. That's the way I did it. [53:58] >> And Katie, the answer there is that Californians don't care what you call it so long as they have affordable healthcare that they can use to take their child to the doctor or the [54:36] >> If you could just point the forum that I said because I've never said it. [55:24] Your response >> look healthcare is expensive, but what we have to do is reduce the cost and expand the coverage to everyone. And that's what I did as secretary. They can ignore those points. They can lie about them. But the fact is by the time I left the secretary position at HHS, we had expanded coverage to more Americans than ever in the history. And we had dropped the cost of care for millions of Americans under Obamacare. [61:16] disqualifying Secretary [61:18] that? Yeah. First, immigrants whether documented or not work hard. They pay taxes and sometimes they get injured on the job or their children get sick. It would be foolish to tell a family that they don't have access to the pediatrician or the family doc or not be able to use the community health center where it wouldn't cost us so much to give them help access to good health care. Instead, what will happen is that child will get so ill that they will have to take that child to the hospital. And what door do they enter? The most expensive door in the health care system, the emergency room door. Why do that and spend so much money when you can do it upfront? And so, yes, let us provide the care to all the people who work hard and make California [62:25] The >> sheriff is supposed to enforce the law. In this case, Sheriff Biano violated the law. There are ways that you treat ballots. You have to maintain the integrity of every ballot. So, you know, I know, we all know that no one will tamper with your ballot. There is a chain of custody requirement that's that the law says you have to follow in order to let that ballot move anywhere. >> Sheriff, >> I believe we broke the law. Sheriff Biano didn't follow that process. He violated the law as the sheriff. So absolutely that's why we are suing to get back the ballots. He cannot claim under cover of an investigation that he is has the right to take these ballots and break that chain of custody. That's against the law. That's why we're suing and that's why he's going to lose in the Supreme [63:56] >> Yeah. That he's being sued by the attorney general, but he's also being sued by those of us who want to protect the ballot. And what we are saying, Sheriff, is that if you're going to try to get a ballot, follow the law. The law is pretty clear. All you had to do was read the law. You cannot take ballots, confiscate them, and count them yourself. You have to have people who are trained and judges to do that. We cannot do that. That's why the Supreme [65:43] Hilton. >> Yeah. First, Steve, read the law. In order to remove ballots, you have to follow a process. Sheriff Bianca didn't follow it. If you're not going to enforce the law as governor, then why would you want to sit in the office? But uh well the point about the same fraud you investigated while you were attorney general >> this issue uh Steve again read the indictment I was not involved in the actions that >> it was your chief of staff you [66:07] >> well actually Javier let me know where [66:13] go ahead >> yeah uh Steve if you knew the law you have to have basis to sue to go after someone criminally I am not involved in that action now your [66:27] You were the one hired to go to [66:44] illegal under state law [66:46] >> Continue responding. >> So you notice that nowhere in the indictment is anything that Steve said included there. If you violate the law, you will be prosecuted. No one is above the law. You will be held accountable. If I had been involved, the US attorney would have had me in that indictment. I was not involved. But here's what I will say, Steve. I hope you speak as ferociously about Donald Trump's violation of the law every time you're sitting in the governor's office trying to protect the people of California because the last thing we need is to have an executive who continues to violate the rights of Californians and have a governor who just sits back and agrees with that executive named Donald Trump. [70:18] the >> as I said, anyone who viol violates the law should be held accountable. If people want to judge me, judge me on what I've done. I expanded healthcare to more Americans than anyone in the history of the country serving as Secretary. I was able to negotiate for the first time ever, lower drug prices as Secretary of Health and Human Services. I took on Donald Trump when he tried to attack the state of California over and over again. If you want to judge me, judge me on the things that I've done, not on scur spurless claims made by people who are trying to become [76:44] >> You'll [76:49] since Wait, time out. [78:58] >> I have to interject. I've been my name has been used several times and [79:03] come to you on Caitlyn, you said that. >> I'll come to you [79:07] worry. [81:56] >> Yeah, I think everyone's invoking my name. It's nice to hear my name quite a bit and they're at least pronouncing it. shouldn't be. Uh, I will tell you this, distorting the facts in your quest to be governor is never good. But using Trump lies to try to uh damage your opponents is worse. And that's what we see happening. Everyone knows that Trump campaigned in 2024 talking about lost kids when there were no such thing as lost kids. To hear these candidates now talk about that, if they're so concerned, why haven't they taken any action to find these lost kids? I think it's shameful for people to use Trump lies to try to gain favor with voters when you know it's not true. Use the facts. We should have a governor who relies on the facts. I will speak the facts when I'm governor because that's what the California voters deserve. I [83:44] >> Gamechanging. [95:22] >> Mr. [103:51] >> I think the fact that I have the experience to take on the toughest challenges, whether it's Donald Trump in his first term or whether it was COVID, something we had not experienced in our lifetime. I've been able to prove that I can balance a budget bigger than the budget of the state of California. I've proven that I know how to tackle a national state of emergency because I've had to do that in the past as Secretary of Health and Human Services. And I proved that I can fight, but more importantly, I can win. And so when someone goes into that governor's office, they're going to have to take a chair and there will will not be training wheels there for them. You have to deliver. And I have a proven record of delivering results. I don't just make inflated promises. Mayor

---
snapshot_id: be0e5e26-45f3-5075-be07-1fb054070448
source_kind: pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)
url: https://www.ontheissues.org/CA/Xavier_Becerra.htm

Xavier Becerra on the Issues Follow @ontheissuesorg On the issues: Xavier Becerra House Match | CA Governor: Antonio Villaraigosa Carly Fiorina David Hadley Delaine Eastin Doug Ose Eric Garcetti Eric Swalwell Gavin Newsom Hilda Solis Jerry Brown Jerry Sanders John Chiang John Cox Kamala Harris Neel Kashkari Travis Allen California Senators: Dianne Feinstein Kevin de Leon Loretta Sanchez Michael Eisen California House Xavier Becerra (Democrat, district 34) On the issues>> Contact Xavier Becerra HouseMatch Take the Quiz! CA politicians Wikipedia Ballotpedia AmericansElect MyOcracy Quiz Huffington Post Quiz Senate races The Web OnTheIssues.org SpeakOut! Use a Selector The Issues 2020 Senate Races All debates AK : Sullivan (R,incumbent) vs. Gross (I) vs. Blatchford (D) AL : Jones (D,incumbent) vs. Tuberville (R) vs. Sessions (R) vs. Moore (R) vs. Rogers (D) vs. Merrill (R) AR : Cotton (R,incumbent) vs. Harrington (L) vs. Whitfield (I) vs. Mahony (D) AZ : McSally (R,incumbent) vs. Kelly (D) …

---
snapshot_id: e4ca1e94-0619-58bd-a3fb-d389465b6250
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [5:15] thank you my parents came to California with $12 in their pocket they worked really hard they never had a chance to go to college but they gave my three sisters and I that very opportunity and as a result we got to live the California dream but too many families today don't believe that the California exists today for them that's why I've been fighting all my public life to make sure that people get to experience what a construction worker and a clerical worker without a college degree had a chance to do that's why I fought to protect the Affordable Care Act when Donald Trump tried to eliminate it the first time he was president and I took him all the way to the Supreme Court and we beat him that's why I had to go at him toe -to -toe over and over more than 120 times when I was attorney general and we beat him whether it was saving the DACA program or whether it was making sure that we protected our families against ICE we fought and we won we're gonna do the same thing again because today it's housing it's health care people want a fighter people want someone with experience I hope to gain your vote [20:10] right in the same way I did it when I was attorney general we establish a bureau that dealt with medical fraud working with the federal government unfortunately Trump is a problem because Trump took a trillion dollars out of the health care system out of the Medicare or them excuse me the Medicaid and the medical system Trump is now trying to deprive California of another billion dollars in health care for medical he doesn't have the right to that you still have to prove that there's been fraud and abuse he is in advance taking money even though he hasn't proven in court what he's done so we should go after him the way I had to do over a hundred and twenty times when I was attorney general we will fight to get those tax subsidies under the Affordable Care Act back for California families we will fight to make sure we get the money that we sent to the federal treasury for medical in California because otherwise three million Californians are in jeopardy of losing their health care we won't let Trump get in our way and whether it's the Trump gas tax because he's recreates a fight the price by going to war in Iran or whether it's the tariffs that are taxed we're gonna fight against Trump [21:18] I absolutely have said over and over yes I do yes I let me just be consistent I have medical for all is a form of single -payer for more than 30 years I have been a proponent an author of legislation for Medicare for Medicare for all which is a form of single -payer and I've done that over and over now what I will tell you is this Ryan what we have to do because people in California don't care what you call it at the end of the day what they want is access to a doctor when they need it and a bill that they can afford to pay and that's what we'll do and when I was secretary I advance more coverage for more Americans than ever before and we lower prices [23:21] sure with with with friends like that who needs enemies right first it's hard to respond to lies we did not dismantle we actually increased oversight in fact [23:32] in fact what we did was we increased oversight over nursing homes because nursing homes had been the place where more deaths occurred as a result of COVID so we actually increased oversight and what I will tell you is this the record speaks for itself Steve under my watch we went to more than 300 million Americans who had health care coverage that was far beyond what Donald Trump your daddy gave us and we are going to continue to move forward in California [24:07] I can because as I've said from day one I was not involved in the wrongdoing I had nothing to do with that I did nothing wrong and don't take my words for it take the words of the u .s. attorney who said no candidate running for governor has been implicated in this particular matter so Steve you may not want to accept it but the truth is what it is you don't get to make up the facts your chief of staff who said [24:40] if I can respond to that if I can respond to that the the district the the prosecuting attorney in the u .s. attorney's office is the one that handled this case Steve unless you've tell me otherwise I don't think you've gone to law school but the u .s. attorney did say and [24:56] Katie to your point then that the the u .s. attorney has said no candidate including me running for governor has been implicated in this case and they looked at all the facts and decided that there was no involvement on my part they want to continue to repeat saying that I get it because it's a campaign except the facts [27:15] this is what happens when you take the lead in the polls and you're ahead of everyone else they all come at you so I get it I'm getting [27:24] it I get it I get it so there they have to try to beat down this is a great Trump tactic that's used I didn't expect it to come from fellow Democrats but it's coming but here's what I will Katie I will quote to you what the US Attorney said no candidate running for governor has been implicated in this case you may not like that but that's what the US Attorney said [32:10] realistically given that we've seen about a hundred a little more than a hundred thousand units built over the last few years if we can double triple that get it to about 300 ,000 that would be a pretty good achievement we have to go beyond that but let's start to unstick the process let's streamline the regulatory process so that we can get developers through the process much quicker let's ask our local governments to stop imposing so many impact fees let's try to make sure that we're working with the local governments to have a statewide coordinated housing policy so it makes sense where we build how we go up we build by transit let's make sure in newer communities we take into account fire hazards and let's make sure that we take into account what property insurance costs because it's hard to buy a house if you can't afford the property insurance for it and so we will do a number of things that's why I've said I will declare a state of emergency when I become a governor to make sure we have the ability the authorities of the governor's office to move this as quickly as possible [40:52] yeah so once again it's it's amazing how people don't read plans and they they try to interpret what other people are saying what I will say to you Matt is this we know what we need to do to try to construct we have to reduce the the regulations that are keeping developers from being able to pencil out projects we know that local governments are very afraid of trying to move too quickly Javier your party if I could just finish Steve and so what we have to do is [41:26] so it's not rocket science what we do have to do is take advantage of what we know can be done quickly there are 40 ,000 shovel ready projects affordable units ready to go if we could just help find the financing when I declare that emergency state of emergency when I get in we will find the money to get those projects on the way but and I will tell you this if you don't believe that we can deal with high home insurance rates Matt then you be running for government we're actually bringing down [42:02] California voters [42:09] do want to [42:13] just finished what is [42:15] just finish the sentence and say yeah [42:22] your [42:27] think [42:30] unfortunate for people for candidates who believe that home insurance costs casualty insurance costs are okay and not try to take this head on grab that bull by the horns because too many families are not able to afford their places their homes because how in home insurance rates have gone sky -high I will tackle that and watch [51:55] Thank you very much. [52:16] so I get a minute to respond to the question in a 30 seconds to respond to miss Porter [52:21] okay so I'll respond to your question and if you give me 30 seconds I'll respond to Katie's question so on artificial intelligence we want to make sure that when artificial intelligence is based here and it should be based here because this is the home of artificial intelligence that it is doing more than just taking care of its own needs it is helping take care the needs of communities that are in California because it is an industry that is going to offer us great opportunity at the same time we want to make sure we're offering the protections that our families need our children our workers we have to make sure that as we harness AI we do it before AI harnesses us and so that means taking advantage of working with them to establish a clear set of rules on how they will operate they will provide resources to have the infrastructure that they need but also expand that to provide the California people with a little extra and we'll do this without imposing the type of regulation that would move them over to places like China. [53:26] Absolutely as the only person who's actually done tax policy because I sat on the Ways and Means Committee for 20 years in the House of Representatives I can tell you what we will do Katie we will make sure that we change the tax code so we don't just tax doctors and nurses and firefighters and teachers at rates that are higher than billionaires like Tom Steyer what we will do is make sure that everyone pays their fair share that won't be so difficult if you look at the governor's budget from this that from today in fact he actually calls for getting rid of some of the corporate welfare loopholes that are allowing corporations to pay less we have the resources to go out and create the revenue we need and we'll make sure that everyone is paying their fair share. We'll make [57:04] Sure Tom. Just look at my record. When I was Attorney General I sued the fossil fuel companies over and over. When I was Attorney General I took on Donald Trump who tried to eliminate California's clean car standards and we beat him. When I was Attorney General I sued oil companies who were trying to monopolize an industry and we beat them. I will stand on my record. I won't have to talk about inflated promises because I could show people what I've done when I was AG and what I will do as governor to make sure that we continue to move towards a transition to clean energy. [57:41] Javier Becerra [58:13] Absolutely not. [66:41] We should not let anyone, whether it's a union or whether it's administrator, get in the way of accountability. We have an obligation and we have laws that require us to make sure that we are enforcing all the obligations that whether you're a classroom teacher or whether you're that principal, you have obligations. As the former chief law enforcement officer for the state of California, we will make sure that we hold people accountable. But the other thing we have to do is recognize that holding people accountable for getting kids to be ready to go to college is a little late. We have to start early because we're baking in mediocrity by not helping children before they even get into kindergarten. And so we have to start much earlier. Child care must be somewhere, a place where people actually get their kids to learn because we want them to be ready not just at the third grade or the sixth grade or the 12th grade. We want them ready before they start kindergarten. And I believe it's time to start going in the direction of early childhood education. And I believe it's time that we started to reduce class size so that it's manageable. No teacher should be asked to take care of 30, 40 kids in one classroom. Expect them to become the next scientists and engineers of our state. [73:21] 67 percent of Californians voted for a woman's right to choose. Thank [73:29] Absolutely no, and when I was AG, I protected reproductive rights here in California. [76:42] I could not support a candidate who would be endorsed by or be supported by Donald Trump because we would have a Donald Trump look -alike in the governor's office, and we can't afford to do that. I would support any of the Democrats who are on this stage. [82:42] I have taken on reckless governments. I have taken on ruthless corporations. I've defended workers' rights, women's health, immigrant rights. I've launched civil rights investigations. I launched 988, the suicide and mental health prevention lifeline. I have overseen a budget larger than the budget of the state of California, four times balancing it. I have declared a state of emergency the only candidate who can say that at the national scale. I have taken on those who are ruthlessly trying to stop Californians for having an opportunity to fight. Not just fight, but to win. I'm the only person who can tell you that the moment I walk into that office, I've been through a challenge that you face when you become the governor of the fourth largest economy in the world. And what you don't need is someone who needs training wheels the moment they walk into that governor's office. We need an adult in the room. And as you've seen today, oftentimes in these candidates, it goes lacking. I hope that what we will do is vote for someone who knows how to manage this crisis on day one.

---
snapshot_id: 261162be-616c-51dd-a14b-72279692734a
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/d770b4c4-dc0a-4f53-b09d-1087ea1bcd4f

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## CA Governor Forum with Ezra Klein - OTR page: https://ontherecord.empowered.vote/meetings/d770b4c4-dc0a-4f53-b09d-1087ea1bcd4f - Video: https://www.youtube.com/watch?v=6HETwu7Kfu8 - Date on On the Record: 2026-05-08 - Kind: forum · CA Gov Candidate Forum · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [17:14] Well, I think the legislature and Assemblymember uh Wicks took the first measures that we need to get us to that point where we can do is make sure that we are building we're building with men and women who are skilled and we're doing it at a price that we can afford. And so, as we've seen, if you do infill housing and you make sure that if you have housing units that will be up to a certain height, up to usually about eight stories. If you're going to do that, then you have the right to be able as a developer to try to get the the labor that you need and try to negotiate a good price. If you go beyond that, you're talking about major construction. Prevailing wage will be the standard. I think that's a good approach. And then, what we do is provide to those that are in the lower height housing the opportunity to go out and do private actions if you find that there are violations of labor laws. But, I will tell you this, we should not believe that we have to build homes by making it so it's impossible for the carpenter who builds a home to never be able to afford to buy it. I'm going to make sure that those workers who are building those homes can actually think about buying those homes themselves. And it all it takes is for us to work together to make sure we are dropping costs. It's far more than just labor. There are a lot of things that are involved here, and we would we would [18:57] decreasing and by [18:58] Well, if we can get rid of the Trump taxes, the tariffs that are now being found illegal, that would help us reduce the cost of building materials. If we could stop going to war in foreign countries >> But, the cost of construction in California was high before Donald [19:12] Trump. It was high, but not as high as it is now. And we can lower those costs. Transportation of building materials is very expensive. And so, let's not disregard that we need Washington, D.C. to be helping us. But to your point, and remember, again, labor costs for most homes that are going to be built will not be based on simply the highest rates that you have in the large mega projects. The legislation that was passed by Assemblymember Wicks provided different ways to do this, which would make the labor costs affordable for developers. We also have to deal with financing. We have to have a stable force of financing source of financing. We can't just do it one time. I think the the measure that Assemblymember Wicks is going to try to put on the ballot is good. I think the measure that former Assemblymember [19:57] for people not following? $10,000 $10 million billion, excuse me, of bonding financing so that you can start building affordable housing. The 40,000 units that Tom mentioned that are ready to go except the financing, that $10 billion would readily available to get those shovel-ready projects up and running, which helps give confidence to the California families that are looking to get into a place. [20:28] your plan says. [20:29] it down? So, one, you you go after the red tape. So, we try to streamline. And again, the legislation that the legislature passed over this last year helps reduce some of the red tape that you have at the state level. We have to attack it at the local level because of the the high fees that are imposed. You have to also make sure that they aren't trying to use their ordinances to try to prevent us from being able to build. Remember that most home most housing that's built today is reserved for single-family homes. Very little construction is done with apartments and condominiums. Very little to buy other than single-family homes. We're never going to reach the number we need if we continue to only build single family homes. And that's why the legislation that allows us to really build out, do the infill where we know we have transportation, will give us an opportunity to increase greater amounts of housing at affordable rates for people who need to either buy or rent. And I think that if we do that and come up with a stable source of funding into the future, so it's not just a one-time housing bond that people can count on, develop developers will begin to have confidence that we are looking to give them a predictable predictable means of being able to finance these projects and have them pencil out. [38:45] governor to align cities with the state? [38:47] As we you have to use every tool you have, and certainly litigation is one. You hate to have to go there. You would hope that you would have cooperation between state and local government. Local governments have for any number of reasons decided they want to be able to control what happens when it comes to housing in their jurisdiction. And they do have tools, zoning laws. We talk about these fees that they try to collect to help with with infrastructure. But what I would say is we have to have an agreement, a state local government agreement, that there has to be a clear path on what the state of California will do when it comes to housing. Every local government must then fall in place to make sure they're doing their fair share. The lawsuit against Huntington Beach was because Huntington Beach had its own housing element plan. It itself had made the made it clear that they needed to build several hundred units of new housing, and then they reneged. And so when we sued them, we said, "It's in your own plan. You're just not willing to do it." The reason we won is because they were violating the law. The case against San Mateo County was simply to make it clear that the state has a role when it comes to housing because while we all are Californians and we're Angelenos or Oaklanders or whatever else, we all have to be able to live in and work and survive in California. So the state of California has a role to play. I defended the the law that said that every jurisdiction is accountable to meet its housing responsibility, and we prevailed in court and found that that law was constitutional, which set the foundation for us to now be able to push and see the legislation that has now become law that's going to let us build [40:47] make the cities that don't want to do it agree with the [40:49] state. Two issues, Ezra, and this I say as the former chief in law enforcement officer for the state of California. The difficulty with enforcement is sometimes the penalties, the fines are never enough. It's almost a cost of doing business to violate the law. You're willing to pay the cost of the fines to not have to go in that direction. The second problem is, of course, it takes forever. And so, I I take when I've been attorney general or when I was Secretary of Health and Human Services on the health care side, the approach I took when there's a law in place that requires you to do something, I would first give you leash. I'd say, "I'm going to give you incentives to do what you're supposed to do under law." At some point though, those incentives go down and at some point we cross over and now becomes penalties. And the penalties grow the longer it takes you to conform to what the law says you have to do. Incent them to come forward, and if after they don't, then start penalizing them for not coming [41:50] Well, we do have some funding that would be available right now in existing housing and community development agency funding, but it's running out. We do need to have a a funding source. The initiatives that are on the ballot to create bonding authority would help us have some of that funding that we would need, but we would have to certainly make sure we're generating the source of funding. The legislature does provide the state with some money. It's not nearly enough, but there is an opportunity to make it clear the funding that the state has will first and foremost be allocated to those who are conforming to their their state law obligations. Those who aren't the money that you could have gotten is going to those who are actually fulfilling their housing [42:44] state's prerogative to tell them what to do? Well, the state same reason kids have to eat their broccoli. I mean, we have we all have to we have to live by rules. I I guarantee you everyone would love to be able to cross through an intersection and not have to worry about the red light, but we have rules. [43:00] >> [laughter] >> Thank god this is California. See, we're not we're not Look, we're a society that believes that we we must and we teach our kids to follow rules. And if you're a city and you see the housing crisis and you're not following the rules, then get ready because I'm going to enforce. I will use the powers of the state working with the Attorney General, working with our Housing and Community Development agencies, and working with those who are willing to push the envelope to say, I'm going to give you a reason to do this building. I'm going to give you an incentive. I'll put you in the front of the line. But at some point you're going to pay the price because we need to build. [48:59] And I believe he is Matt didn't identify the project specifically, but this was a project in the San Diego County area that was in the hills in wildland wildfire risky areas. Uh it was a pretty large development, several thousand units. It had one route for egress. And we went to the developer, and we went to the county and said, "This is a safety hazard. This is something that could cause lead to the loss of life if indeed we have a wildfire." This was when I was AG between 2018 uh 2017 and 2021, way before Palisades and Altadena. And we simply said to them, "If you're going to build that many housing units, and people are going to be living up there, and there's a wildfire that hits, you better have a way for these folks to be able to save their lives. Having one route of egress was not going to do it." So we said to them, "If you're not going to take care of this, guess what? We're going to have to sue you." We tried we tried not to do the litigation, but sometimes that it does help to have someone who knows how to enforce the [67:53] We didn't focus on outcomes. Uh there were the accountability wasn't there. $24 billion was there, but the outcomes didn't result. We didn't see that people were moved off the street fast enough. We didn't provide the services they needed. To me, the homelessness crisis is as much a mental health crisis as it is someone needing a place of shelter. And we didn't provide the types of resources to make sure we could stand people up and make sure they wouldn't go back to the streets. Uh I I also believe that we have to do far more to prevent people from ever becoming homeless. I don't have control of the streets of Los Angeles, of Oakland, or the counties as governor. What I can control is the monies that we send and try to demand accountability. But the most important thing I I believe, and this is where I will focus as governor, is trying to help that person that is on the very edge of losing their housing, whether it's their home or their apartment that they're renting. Because there are people who under some circumstances, you lose your job unexpectedly. You're trying to get back to work and it's taking you a little longer. You used up your savings. You're on the verge now of losing your apartment that you're renting. You have a medical emergency. You break your piggy bank open, you use it all up, it's not enough, you still have a big bill. All of a sudden, you have to make a decision. Do you pay the bill or do you stay in your home? And I believe those are the folks that if we provided more support, and I would create a stabilizing fund that would be there for to help those Californians who are in a home, make sure they don't lose their home. It will cost us far less to invest in someone maintaining their housing than trying them off the street, get them to stand up, provide them the services, get them the temporary shelter, and then help them get re-employed. And so, let's invest in prevention before we start talking about just trying to pick people off the [70:07] that be? First, I think we have to give everyone an opportunity to have an out. And when I established the 988 program, and I hope some of you are familiar with it, it's like 911 but for mental health crisis and suicide prevention. And if you dial 988 or actually text or chat, you'll get someone who'll help you, not as a police officer, but as someone who can provide you services. We do that. We have a dedicated line for veterans who are hurting. We had We had, but this administration took it away, a line for LGBTQI who wanted to be able to speak to somebody who would understand their concern. We have to give people an out, an opportunity. But what happens too often is we don't do that, and then we don't do the second thing is to make sure that we tell folks, we are your keeper. I am my brother and my sister's keeper. We will not let you languish in the streets. And if you keep saying no, and it's clear that you need help, then it's really our responsibility as civilized people to make sure we provide our brother or sister some assistance. And so, I think we have to get to that point. We don't let people make that decision when it's clear they're not making the right decisions for [71:38] Very similar to the the carrot and stick approach, which I use, by the way, at HHS, we had to help doctors switch from paper record keeping, prescriptions, their medical records, to digital, to finally join the electric electronic world. A lot of folks said, "We can't afford it." And so, what we did was we scaled it. We said, "Look, we're going to give you incentives to uh change your practice into one that can uh function electronically. And we're going to give you incentive, incentive, but at some point, it's going to become penalty, penalty, penalty if you don't join the real world." Uh we would do the same thing. There's a locality. You're not You have programs, but they're not resulting in success, then we have to terminate those programs or stop the funding. I will then scale those programs that are working. I'll take the money from the programs that aren't working, and I'll scale those programs that are working. And that's what you have to do is you have to carrot and stick, but I will use the stick at the end of the day because taxpayers are paying for folks to be pulled Mr. Steyer, [96:16] Becerra. Uh let me give you something uplifting after this conversation. >> [laughter] >> Uh there's a a book called Rain of Gold by Victor Villasenor, which is all about how if you just put your mind to it, you can lift up your family and have success. It's the American dream in this book and it's a Rain of Gold. I love that book. Ms. Porter.