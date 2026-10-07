You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-thomson-nosource/labels/coder-2.json. Write JSON only, matching
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

politician_id: 1c6dbdaf-e110-48d3-9b88-27f911d9521f  office_id: b42f6de3-da88-4d50-af66-c78cdb46e628
Kerry Thomson — City Mayor, Indiana (seated, level: local)
Current term: unknown (precision: unknown) to present

## Topics (served ladder text — code against these words only)

### topic_key: abortion
topic_id: af2fdfd6-02c4-49df-b09c-cf8536f4773f  served_revision_id: 085feb9c-f157-4dae-bfd0-7b2736c5d87c
Question: How should the law handle abortion?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: ai-regulation
topic_id: 666bf03d-81fc-4138-ab15-69ae734c9023  served_revision_id: c594dc06-0c70-4707-8ae0-d4bc760172db
Question: How much should government oversee artificial intelligence development and deployment?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Allow AI companies to develop and deploy technology freely without government interference
  2. Suggest AI safety guidelines but let companies choose whether to follow them
  3. Hold AI developers legally responsible when their systems cause harm
  4. Require safety testing before AI can be used in high-stakes areas like hiring, healthcare, and policing
  5. Impose strict government approval requirements before any AI system can be deployed

#### Annex

# ai-regulation — served revision c594dc06-0c70-4707-8ae0-d4bc760172db (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How much should government oversee artificial intelligence development and
deployment?"

**Orientation:** **inverted.** Rung 1 is the **least** government action (no interference), rung 5 the
most (approval before any deployment). Read the rung text, not the number (CLAUDE.md "Never assume
polarity").

**Levels with a lever:** federal, state. Both legislate; local governments
are not asked on this topic.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "automated decision system" (ADS), "automated employment decision tool", "consequential
decision", "high-risk artificial intelligence system", "algorithmic discrimination", "frontier model",
"covered model", "foundation model", "developer" and "deployer", "bias audit", "impact assessment",
"red-teaming", "watermark" or "provenance", "AI Risk Management Framework" (NIST), "AI moratorium".

1. **"Allow AI companies to develop and deploy technology freely without government interference"**
   - Means: government places no rules on how AI is built or used.
   - Operative clauses: [a] free development and deployment; [b] without government interference.
   - Establishing evidence looks like: own words that reject any government rule on AI. [b] is an
     absence clause: a vote against one AI bill does not show that the person rejects every rule
     (V4.2 "Silence is not a clause") → `direction-only`.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because "remove regulations" sounds like rung 1. With no regulation
     named it is V7 `direction` (codebook H10, Hilton / ai-regulation) and, as stance evidence,
     `direction-only`.

2. **"Suggest AI safety guidelines but let companies choose whether to follow them"**
   - Means: government writes safety guidance, and following it is voluntary.
   - Operative clauses: [a] government issues safety guidelines; [b] compliance is voluntary.
   - Establishing evidence looks like: an instrument that tells an agency to publish guidelines or a
     framework and states that compliance is voluntary; own words for voluntary standards over
     mandates _(proposed)_.
   - Levels that hold a lever: federal (agency frameworks); state (state guidance, executive orders).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because an order to **study** AI, convene a task force or report is
     not a guideline → `study-directive`.
   - Commonly confused with rung 3 when a bill pairs voluntary guidelines with a legal duty. The
     binding clause decides the rung.

3. **"Hold AI developers legally responsible when their systems cause harm"**
   - Means: the companies that build AI can be made to answer in law for harm their systems cause.
   - Operative clauses: [a] legal responsibility (liability, a cause of action, a penalty); [b] on the
     developer or company; [c] for harm the system causes.
   - Establishing evidence looks like: operative text that creates liability for harm caused by an AI
     system, where the liable party **can be the company** that made or provided it → rung 3. If the
     text reaches only an individual who misuses AI, [b] is not met → `direction-only` _(proposed)_.
     A general liability statute that does not name AI developers but reaches them meets [b].
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **disclosure or labelling** duty (watermarks, provenance,
     telling users they are dealing with AI) feels like accountability. Disclosure was taken out of
     this rung in Season 2 → BLANK `direction-only` _(ruled 2026-09-01: disclosure-only rows fit no
     rung)_.
   - Commonly confused with rung 4 because many bills test **and** assign liability. A pre-use testing
     duty is rung 4 _(ruled 2026-09-01: rows resting on safety-testing bills moved from 3 to 4)_.

4. **"Require safety testing before AI can be used in high-stakes areas like hiring, healthcare, and
   policing"**
   - Means: before AI is used for decisions in sensitive areas, the law requires it to be tested.
   - Operative clauses: [a] required safety testing; [b] before use; [c] in a high-stakes area. Hiring,
     healthcare and policing are examples ("like"), not the full list.
   - Establishing evidence looks like: operative text that requires testing of an AI system before it
     is used for consequential decisions. A testing duty limited to named high-stakes uses excludes
     rung 5 by its own text (as in codebook V4.2, Adams / trans-athletes).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because duties on **users** of AI (not developers) are oversight,
     not testing, and not developer liability → BLANK `direction-only`.
   - A required pre-use **bias audit** counts as safety testing when it tests the system's outputs
     before use. An impact assessment that is only a report, with no test → `direction-only` _(ruled 2026-10-01)_.
   - A pre-deployment testing duty scoped by **model size** (frontier or covered models), not by use
     area, meets the testing clause but not "in high-stakes areas" → `compound-partial`. It is not
     rung 5 (testing is not approval). A duty only to publish a safety framework → `direction-only`
     _(ruled 2026-10-01)_.

5. **"Impose strict government approval requirements before any AI system can be deployed"**
   - Means: no AI system may be deployed until government approves it.
   - Operative clauses: [a] government approval or licence; [b] before deployment; [c] of **any** AI
     system.
   - Establishing evidence looks like: own words or operative text for a licence or approval regime
     that covers AI systems in general. [c] is universal; approval for one class of system is not it.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both act before deployment. Rung 4 tests in named areas;
     rung 5 needs approval for all systems.
   - A **ban or moratorium on one use** (deepfakes, facial recognition, rent-setting algorithms,
     chatbots for children) is not universal approval, and Season 2 has no ban rung → BLANK
     `direction-only` _(ruled 2026-09-01: targeted-ban rows fit no rung)_.

**Hard cases:**
- **Preemption (codebook V2, H12).** A federal bill that forbids or pauses state AI laws decides which
  level may regulate, not how much → `adjacent`.
- **Government's own use of AI** (agency inventories, procurement rules, a chief AI officer) is not
  oversight of AI development and deployment in general → `adjacent` _(proposed)_.
- **Election deepfakes and synthetic media** also belong to `misinformation`; here they are a targeted
  ban or a label → BLANK `direction-only` (see rungs 3 and 5).
- **Budget and omnibus votes** with an AI item → V4 `multi-subject`.
- **A governor's signature or veto** is a record; code the bill's operative clause as above.


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


### topic_key: city-sanitation
topic_id: 7687de4f-4d0b-462a-b803-bdfb23b16b42  served_revision_id: af3c2445-97e5-46a7-b33d-6915c13eab5c
Question: How should your community approach street cleanliness and sanitation?
  1. Significantly expand public sanitation services, treating cleanliness as the city's responsibility
  2. Concentrate sanitation resources on the most neglected, worst-served neighborhoods to close long-standing service gaps
  3. Maintain current public sanitation services and target enforcement at the businesses and large property owners who create the most waste
  4. Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible
  5. Privatize sanitation services and require residents and businesses to contract for cleanup directly

#### Annex

# city-sanitation — served revision af3c2445-97e5-46a7-b33d-6915c13eab5c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should your community approach street cleanliness and sanitation?"

**Orientation:** standard. Rung 1 makes cleanliness a public service the city expands, rung 5 moves
the service to private contracts that each resident and business pays for. The rungs order **who is
responsible for keeping streets clean**: the city (1–3), the people who make the mess (3–4), or the
private market (5). Rung 2 is an **allocation** choice (where the service goes), not a smaller amount
than rung 1.

**Levels with a lever:** local. The lever is the city or county budget, the
sanitation or public-works department, and local codes on litter, dumping and property upkeep. A
state or federal officeholder holds no lever here → `scope-unavailable`.

**Asked at:** local (`compass_topic_roles`, CA_0302).

**Synonyms:** "solid waste", "refuse collection", "street sweeping", "bulky-item pickup", "illegal
dumping", "blight", "code enforcement", "property maintenance code", "nuisance abatement",
"clean-up days", "franchise hauler", "exclusive franchise", "open market collection", "subscription
service", "public works".

1. **"Significantly expand public sanitation services, treating cleanliness as the city's
   responsibility"**
   - Means: the city provides much more cleaning and collection itself, because keeping streets
     clean is its job.
   - Operative clauses: [a] a significant expansion of public sanitation services; [b] cleanliness
     treated as the city's responsibility.
   - Establishing evidence looks like: a single-subject vote or budget amendment that adds crews,
     routes, sweeping frequency or free disposal **across the city**; own words that the city, not
     residents, must keep streets clean. [b] is usually met by the same passage as [a]; it is what
     excludes rung 4 _(proposed)_.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because an expansion aimed at named neighbourhoods is both "more"
     and "concentrated". Code the clause the passage states: an expansion **citywide** is rung 1; new
     resources **directed to the worst-served areas** is rung 2. A passage that does both and says
     neither is the main aim → `direction-only` _(proposed)_.
   - A small pilot or a one-time clean-up day is not "significantly expand" → `direction-only`
     _(proposed)_.

2. **"Concentrate sanitation resources on the most neglected, worst-served neighborhoods to close
   long-standing service gaps"**
   - Means: the city puts its sanitation effort first into the areas that have been served worst.
   - Operative clauses: [a] concentrate resources on the most neglected, worst-served neighbourhoods;
     [b] the purpose is to close long-standing service gaps.
   - Establishing evidence looks like: a programme, budget line or service standard that directs
     crews or money to areas identified by poor service or long neglect; own words that the gap
     between neighbourhoods is the problem to fix.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1. A general expansion with no targeting does not meet
     [a] (this is the clause that separates the two rungs).
   - A council member who asks for more service **in their own district** has not shown [a] or [b]:
     the district is not shown to be worst-served, and the request may be ordinary constituent work
     → `direction-only` _(proposed)_.

3. **"Maintain current public sanitation services and target enforcement at the businesses and large
   property owners who create the most waste"**
   - Means: keep the city's service at today's level, and aim enforcement at the biggest commercial
     sources of waste.
   - Operative clauses: [a] maintain current public services (no significant expansion, no cut);
     [b] target enforcement at businesses and large property owners.
   - Establishing evidence looks like: an ordinance or enforcement programme aimed at commercial
     dumping, commercial-property upkeep or large generators, **plus** a passage that keeps public
     service at its present level. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both use enforcement. Rung 3 aims it at **businesses and
     large owners** and keeps the public service; rung 4 makes enforcement the **main** tool and holds
     **residents** responsible too. An anti-dumping law that applies to everyone does not meet [b]
     → it supports rung 4 [a] at most _(proposed)_.

4. **"Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents
   and businesses responsible"**
   - Means: the main tool is fines and code enforcement, and the people who make the mess are
     responsible for it.
   - Operative clauses: [a] enforcement of litter and property-maintenance laws as the **primary**
     approach; [b] residents and businesses held responsible.
   - Establishing evidence looks like: own words that enforcement, not more city service, is the
     answer; a vote that raises litter or code fines or adds enforcement officers **and** a passage
     that rejects expanding service. An enforcement measure **added to** current service does not
     show "primarily" → `direction-only` _(proposed)_.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.

5. **"Privatize sanitation services and require residents and businesses to contract for cleanup
   directly"**
   - Means: the city stops providing the service, and each resident and business hires and pays a
     private provider.
   - Operative clauses: [a] privatize sanitation services; [b] require residents and businesses to
     contract directly.
   - Establishing evidence looks like: a vote or own words to end city collection and move every
     household and business to its own private contract. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - A city contract with one private hauler (the city still pays and stays responsible) is not
     privatization: it changes who does the work, not who is responsible → `adjacent` _(ruled 2026-10-01)_.

**Hard cases:**
- **Budget and omnibus votes** with a sanitation line → V4 `multi-subject`.
- **Fee and rate votes** (a solid-waste fee increase) fund the current service; alone they do not
  show expansion (rung 1) or maintenance (rung 3) → `direction-only` _(proposed)_.
- **Encampment clean-ups** are about homelessness, not sanitation service → `adjacent` (the
  homelessness topics hold them) _(proposed)_.
- **Recycling and organics rules** (what residents must sort) are waste policy, not street
  cleanliness → `adjacent` unless the passage presents them as the city's main tool for clean
  streets _(proposed)_.
- **Near-unanimous** clean-up resolutions and service-day proclamations → `near-unanimous` or
  `rhetorical`.


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


### topic_key: fossil-fuels
topic_id: a22215c3-6693-4bc2-b248-01aebba14570  served_revision_id: 58796165-cd12-44de-a9b6-84df43f6eda0
Question: What role should fossil fuels play in the nation's energy future?
  1. Phase out fossil fuel production entirely.
  2. Allow no new drilling and let production decline over time.
  3. Keep fossil fuel production steady at current levels.
  4. Expand fossil fuel production with new drilling and permits.
  5. Maximize production and open more public land and waters to drilling.

#### Annex

# fossil-fuels — served revision 58796165-cd12-44de-a9b6-84df43f6eda0 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should fossil fuels play in the nation's energy future?"

**Orientation:** standard. Rung 1 ends fossil fuel production, rung 5 maximizes it. The rungs order
the **trajectory of production** — end it, let it decline, hold it, grow it, maximize it — not
emissions rules or clean-energy policy.

**Levels with a lever:** federal, local, state. The lever is leasing and
permitting: federal (federal lands and offshore waters), state (state lands, well permits, the oil
and gas commission). Local governments hold a lever only where state law lets them zone or ban
drilling.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "oil and gas lease sale", "Outer Continental Shelf" (OCS), "five-year leasing
program", "application for permit to drill" (APD), "hydraulic fracturing" or "fracking", "setback",
"buffer zone", "keep it in the ground", "managed decline", "energy dominance", "extraction",
"severance tax", "coal lease", "moratorium".

1. **"Phase out fossil fuel production entirely."**
   - Means: all fossil fuel production ends, including from wells and mines that operate now.
   - Operative clauses: [a] a phase-out of production; [b] entirely — existing production ends too.
   - Establishing evidence looks like: an instrument that ends existing production by a date or
     schedule; own words calling for an end to all production. [b] separates rung 1 from rung 2, so
     a ban on **new** drilling alone does not reach it.
   - Levels that hold a lever: federal (federal lands and waters); state (state permits); local only
     where state law allows a local ban.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.
   - A ban on one technique (for example fracking) or one fuel is narrower than "entirely" →
     `direction-only` _(proposed)_.

2. **"Allow no new drilling and let production decline over time."**
   - Means: no new wells or leases; existing production continues and falls off over time.
   - Operative clauses: [a] no new drilling; [b] existing production is allowed to decline, not ended.
   - Establishing evidence looks like: a jurisdiction-wide bar on new drilling permits or new leases
     that leaves existing wells in place _(proposed)_. [a] is an absence clause ("no new"): the
     instrument must bar new drilling across the jurisdiction, not in part of it (V4.2).
   - Levels that hold a lever: federal; state; local only where state law allows it.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because both stop new drilling. Code rung 1 only when the passage
     also ends existing production.
   - Commonly confused with BLANK because a **geographic limit** on new wells reads like "no new
     drilling". A siting limit on new wells is on-question (it is about new drilling) but covers only part of the jurisdiction →
     BLANK `direction-only`. The same for one region, one basin or one stretch of coast.
   - A **temporary pause** on lease sales or permits, pending a review, is not "no new drilling" →
     `direction-only` _(proposed)_; the review part is `study-directive`.

3. **"Keep fossil fuel production steady at current levels."**
   - Means: production stays about where it is now, neither cut nor grown.
   - Operative clauses: [a] production held at current levels.
   - Establishing evidence looks like: own words that production should neither fall nor grow.
     Instruments rarely state this, so expect statements _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a person who opposes both a ban and an expansion looks like
     rung 3. Ruling out rungs 1, 2, 4 and 5 is not evidence for rung 3 (V4.2 "Ruling out the other
     rungs") → `direction-only`.
   - Environmental rules are no longer part of this rung. A vote on emissions or safety rules does not
     place a person here → `adjacent`.

4. **"Expand fossil fuel production with new drilling and permits."**
   - Means: production grows, through new wells, new leases and more permits.
   - Operative clauses: [a] expand production; [b] by new drilling and new permits.
   - Establishing evidence looks like: an instrument that requires lease sales, speeds or adds
     drilling permits in areas already open; own words calling for more drilling. A single record of
     this kind does not exclude rung 5, so it is `direction-only` unless a second passage excludes
     "maximize" (for example own words that keep some areas closed) _(proposed)_.
   - Levels that hold a lever: federal; state; local (local permits where they exist).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both expand. Rung 5 adds two clauses: "maximize" and
     opening **more** public land and waters.

5. **"Maximize production and open more public land and waters to drilling."**
   - Means: produce as much as possible, including by opening public land and waters that are closed
     to drilling now.
   - Operative clauses: [a] maximize production; [b] open more public land and waters to drilling.
   - Establishing evidence looks like: an instrument that opens closed public land or offshore areas
     to leasing **and** own words or text that call for maximum production. Compound: one side only
     → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal (federal lands and the OCS); state (state lands and state
     waters). Local governments hold no lever on [b].
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4. A deregulation law cannot show "maximize" on its own:
     that is a magnitude (codebook V2, refined 2026-09-26) → `direction-only`.
   - Removal of environmental restrictions is no longer this rung's clause. It is evidence for
     neither [a] nor [b] on its own → `direction-only` _(proposed)_.

**Hard cases:**
- **Preemption (codebook V2, H12).** A state law that forbids local governments to ban drilling, or to
  ban new gas hookups, decides which level may act → `adjacent`. A hookup rule is also about using gas,
  not producing it; the climate-change annex makes the same call.
- **Use, transport and export** (gas hookups, pipelines, refineries, export terminals, power-plant
  fuel) are not production → `adjacent` _(proposed)_.
- **Emissions and safety rules** (methane limits, flaring rules, well plugging, spill rules) →
  `adjacent`. They regulate how production happens, not how much.
- **Clean-energy measures** (a renewable standard, clean-energy credits) belong to `climate-change` →
  `adjacent` here.
- **Taxes and subsidies** (severance tax rates, production tax breaks, royalty rates) change the cost
  of production, not its permitted level → `direction-only` at most _(proposed)_.
- **Budget and omnibus votes** that contain a leasing or permitting item → V4 `multi-subject`.
- **"All of the above"** or "energy independence" with no production clause → `rhetorical`.


### topic_key: healthcare
topic_id: e8dad4a8-eb93-4931-91f5-d8fb5d7dd529  served_revision_id: 87719e15-58aa-4729-a73f-d47e64d5a954
Question: What role should government play in healthcare access?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Make healthcare free and available to everyone, fully paid for by the public sector
  2. Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance
  3. Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else
  4. Only help the poorest people afford healthcare and leave everyone else to employers and private insurance
  5. Stay out of healthcare entirely and let private markets handle all coverage decisions

#### Annex

# healthcare — served revision 87719e15-58aa-4729-a73f-d47e64d5a954 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`afc91aa2-…`); coders code the served text below.

**Question:** "What role should government play in healthcare access?"

**Orientation:** standard. Rung 1 has the public sector pay for everyone's care, rung 5 gives
government no role. The rungs order **whom government covers or helps pay for**: everyone in full,
everyone through a mix, people who cannot afford care plus seniors, only the poorest, no one.

**Levels with a lever:** federal, state. The levers are federal law (Medicare,
marketplace subsidies, insurance rules) and state law (Medicaid eligibility, state exchanges and
subsidies, state insurance regulation). Local governments hold no lever on coverage.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "single-payer", "Medicare for All", "universal coverage", "public option", "Affordable
Care Act" (ACA, "Obamacare"), "marketplace" or "exchange", "premium tax credit", "cost-sharing
reduction", "Medicaid expansion", "CHIP", "individual mandate", "pre-existing conditions",
"guaranteed issue", "essential health benefits", "short-term plans", "health savings account" (HSA),
state Medicaid names ("Medi-Cal", "AHCCCS", "BadgerCare", "MassHealth").

1. **"Make healthcare free and available to everyone, fully paid for by the public sector"**
   - Means: one public payer covers every resident, with no charge to the patient. (Rung 1 no longer
     says the public sector *runs* care; the S1 description's "publicly administered" is not a
     clause.)
   - Operative clauses: [a] everyone; [b] free to the patient; [c] fully paid for by the public
     sector.
   - Establishing evidence looks like: authoring or co-sponsoring a single-payer bill whose operative
     text enrolls every resident and bars premiums and cost-sharing; own words calling for that.
   - Levels that hold a lever: federal; state (a state single-payer plan).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because "universal coverage" and "public option" do not remove
     private insurance or cost-sharing. A plan that keeps private insurance beside a public plan →
     rung 2 territory, not rung 1.
   - Private hospitals and doctors do not exclude rung 1: the rung is about who **pays**, not who
     delivers care _(proposed; the reason "and run by" was dropped, CA_0055)_.
   - "Healthcare is a human right" names no clause → `rhetorical`.

2. **"Make sure everyone has affordable coverage through a mix of public programs and regulated
   private insurance"**
   - Means: the goal is coverage for every person, reached through public programmes and private
     insurance under public rules.
   - Operative clauses: [a] everyone covered; [b] affordable; [c] a mix of public programmes and
     regulated private insurance.
   - Establishing evidence looks like: an instrument that aims at coverage for every resident through
     both a public route (a public option, subsidies, Medicaid) and rules on private insurers; own
     words that name coverage for everyone **and** keep private insurance.
   - Levels that hold a lever: federal; state (state exchanges, state subsidies, a state public
     option).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because both expand public programmes and keep private insurance.
     The separating clause is [a] **everyone**. A measure that helps only people who cannot afford
     care does not reach [a] → rung 3 territory.
   - A vote or statement that **defends or expands the ACA** as a whole → `direction-only`: the ACA
     matches rung 3 too, so it excludes neither; rung 2 needs evidence of "everyone" _(ruled 2026-10-01)_.
   - Pre-existing-condition protection on its own regulates private insurance but says nothing on
     [a] → `direction-only` _(proposed)_.

3. **"Help people who can't afford care and expand programs for seniors and low-income residents,
   while keeping private insurance for everyone else"**
   - Means: government helps people who cannot pay and widens the programmes for seniors and
     low-income people; everyone else stays on private insurance.
   - Operative clauses: [a] help people who cannot afford care; [b] **expand** programmes for seniors
     and low-income residents; [c] keep private insurance for everyone else. Compound: one side only
     → `compound-partial` (V4.2).
   - Establishing evidence looks like: a single-subject expansion of Medicaid or of Medicare benefits
     **plus** a passage that keeps private insurance as the main route for others (this excludes
     rungs 1 and 2). An expansion vote alone matches rungs 2 and 3 alike → `direction-only`
     _(proposed)_.
   - [b] lists the two programme populations. Expanding one of them meets [b] _(proposed)_.
   - Levels that hold a lever: federal (Medicare, federal Medicaid rules); state (Medicaid
     eligibility and benefits).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a person who keeps Medicaid **as it is** has not expanded
     it. Keeping a programme is not [b] "expand" → not rung 3 on that passage.

4. **"Only help the poorest people afford healthcare and leave everyone else to employers and
   private insurance"**
   - Means: public help goes to the poorest people and to no one else.
   - Operative clauses: [a] help for the poorest; [b] "only" — no public help beyond them (an absence
     clause: the passage must say it, V4.2 "Silence is not a clause"); [c] everyone else to employers
     and private insurance.
   - Establishing evidence looks like: own words that public help should be limited to the poorest;
     an instrument that narrows eligibility to the poorest and says so.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A repeal of a Medicaid expansion excludes rung 3 [b], but it does not state [b] "only" →
     `direction-only` _(proposed)_.
   - "Only the poorest" is read for people **below Medicare age**; it does not require ending Medicare
     for seniors. Medicare's structure is coded on `medicare/aid` _(ruled 2026-10-01)_.
   - Commonly confused with rung 5 because cutting a programme is not leaving healthcare
     **entirely**. A cut that keeps any programme → not rung 5.

5. **"Stay out of healthcare entirely and let private markets handle all coverage decisions"**
   - Means: no public coverage programmes and no government rules on coverage.
   - Operative clauses: [a] no government role ("entirely"); [b] private markets decide **all**
     coverage. Both are absence clauses; the passage must state them (V4.2).
   - Establishing evidence looks like: own words that call for ending public coverage programmes
     **and** coverage rules.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because deregulating private insurance (short-term plans, sales
     across state lines, HSAs) moves toward the market but ends no programme → `direction-only`
     _(proposed)_.

**Hard cases:**
- **Health information is not access.** A measure that has an agency or provider give out
  information or materials about a specific condition does not say whom government covers →
  `adjacent`; BLANK `no-evidence` when nothing else survives.
- **The omnibus trap (codebook V4, [real]).** A Yea on the One Big Beautiful Bill Act (2025), a
  reconciliation bill that covers taxes, Medicaid, immigration and more → `multi-subject`. Statements
  that defend its **work requirements** are about a narrower clause than any rung → `adjacent`.
- **Medicaid work requirements** on their own → `adjacent` _(proposed, from the same codebook
  example)_.
- **Drug prices, insulin caps, price transparency, mental-health parity** regulate cost or benefits,
  not who is covered → `adjacent` _(proposed)_. (Medicare cost control is on `medicare/aid`.)
- **A Medicare for All bill** can be coded on both `healthcare` and `medicare/aid`. Code each topic
  on its own rung text; a match on one topic is not a match on the other.
- **Preemption (codebook V2, H12)** → `adjacent`.
- **Budget votes** that fund an existing programme → V4 `multi-subject`.


### topic_key: jail-capacity
topic_id: c267e137-0ff9-4e7d-9d13-e3cea1756cd0  served_revision_id: 7992fadf-a24c-4f73-bd34-76b5bca4764b
Question: How should government respond to jail overcrowding and criminal justice demand?
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


### topic_key: medicare/aid
topic_id: cab61e8a-64fe-4bbd-bc08-fe9914d0091b  served_revision_id: 38bab357-9790-4cb3-a6d2-c43cbdca615b
Question: How should Medicare and Medicaid be funded and structured?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. expand Medicare to cover everyone regardless of age
  2. significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage
  3. improve current programs while controlling costs
  4. scale back both programs, shifting more coverage to private insurance
  5. phase out both programs and use private insurance only

#### Annex

# medicare/aid — served revision 38bab357-9790-4cb3-a6d2-c43cbdca615b (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Medicare and Medicaid be funded and structured?"

**Orientation:** standard. Rung 1 makes Medicare cover everyone, rung 5 ends both programmes. The
rungs order **how large the two public programmes are**: universal, larger, the same, smaller, none.

**Levels with a lever:** federal, state. Medicare is federal only. Medicaid is
joint: Congress sets the frame and the federal share; each state sets eligibility, benefits and
waivers inside it. So a state officeholder holds a lever on Medicaid and none on Medicare.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "Medicare Part A / B / C / D", "Medicare Advantage", "traditional Medicare", "premium
support", "voucher", "Medicare buy-in", "Medicare at 60" (or 55, 50), "Medicare for All",
"Medicaid expansion", "FMAP" (federal share), "block grant", "per-capita cap", "section 1115
waiver", "work requirements" or "community engagement", "CHIP", "dual eligibles", "drug price
negotiation", state Medicaid names ("Medi-Cal", "AHCCCS", "BadgerCare", "MassHealth", "TennCare",
"Healthy Indiana Plan").

1. **"expand Medicare to cover everyone regardless of age"**
   - Means: Medicare becomes the coverage for every person, of any age.
   - Operative clauses: [a] Medicare (the federal programme, or a programme that replaces it for
     all); [b] everyone, regardless of age.
   - Establishing evidence looks like: authoring or co-sponsoring a Medicare for All bill that enrolls
     every resident; own words calling for Medicare for everyone.
   - Levels that hold a lever: federal. A state cannot expand Medicare; a state single-payer plan is
     not Medicare → code it on `healthcare`; here a state officeholder's rung 1 is `scope-unavailable`
     (codebook 0.4 principle 5) _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a buy-in or a lower Medicare age is an expansion that
     stops short of everyone → rung 2.

2. **"significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage"**
   - Means: many more people qualify for one of the two programmes, but not everyone.
   - Operative clauses: [a] **eligibility** for Medicare **or** Medicaid (one programme is enough);
     [b] significant; [c] short of universal.
   - Establishing evidence looks like: a single-subject bill or vote that lowers the Medicare age, or
     adopts the adult Medicaid expansion in a state; own words calling for such a change. Code the
     end state the instrument enacts: an instrument that stops short of everyone meets [c]; it does
     not need a second passage that rejects rung 1 _(proposed; adjudicated gold on another topic
     seated an instrument that met every clause of one rung, but not the extra clause of the
     stronger rung beside it, on the rung it met)_. If a surviving rung-1 passage also exists → V6
     `adjacent-chairs` rules apply.
   - Levels that hold a lever: federal (Medicare age, federal Medicaid rules); state (Medicaid
     eligibility).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **narrow** eligibility change (one group, such as
     12-month postpartum coverage) is an expansion but not "significant" → `direction-only`
     _(proposed)_.
   - Benefits are not eligibility. Adding dental, vision or hearing to Medicare improves the programme
     → rung 3 clause [a], not rung 2 _(proposed)_.
   - S1 rung 2 named "lower Medicare age to 55 **and** expand Medicaid"; the served rung needs one of
     the two, not both.

3. **"improve current programs while controlling costs"**
   - Means: keep the two programmes' present shape, make them work better, and hold down what they
     cost.
   - Operative clauses: [a] improve current programmes (benefits, access, quality, administration);
     [b] control costs (drug price negotiation, payment reform, fraud and waste). Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a single-subject Medicare or Medicaid bill that does both, or
     two passages that each match one clause, inside current eligibility.
   - Levels that hold a lever: federal; state (Medicaid administration and payment rates).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because "controlling costs" can mean cutting coverage. A cut in who
     is covered is rung-4 territory, not [b].
   - "Protect Medicare", "no cuts to Medicare" names no clause → `direction-only` (it excludes rungs
     4 and 5 only).

4. **"scale back both programs, shifting more coverage to private insurance"**
   - Means: both Medicare and Medicaid cover less, and private insurance covers more.
   - Operative clauses: [a] scale back Medicare; [b] scale back Medicaid; [c] shift coverage to
     private insurance. Compound: one programme only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a premium-support or voucher plan for Medicare **and** a
     Medicaid cut or cap (block grant, per-capita cap, eligibility rollback); own words calling for
     both.
   - Levels that hold a lever: federal for [a] and [b]; state for [b] only.
   - At state level, a Medicaid-only scale-back → `compound-partial`: the rung says "both" _(ruled 2026-10-01)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Medicare Advantage growth alone moves enrollees to private plans **inside** Medicare; it does not
     scale back the programme → `direction-only` _(proposed)_.
   - S1 rung 4 named "partially privatize Medicare **and** reduce Medicaid"; the served rung is about
     size ("scale back"), and needs both programmes.

5. **"phase out both programs and use private insurance only"**
   - Means: Medicare and Medicaid end, and private insurance is the only coverage.
   - Operative clauses: [a] phase out Medicare; [b] phase out Medicaid; [c] private insurance only (an
     absence clause: the passage must say it, V4.2).
   - Establishing evidence looks like: own words that call for ending both programmes.
   - Levels that hold a lever: federal. A state can leave Medicaid but cannot end Medicare → same
     scope question as rung 4.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a deep cut is not a phase-out. A plan that keeps either
     programme → not rung 5.

**Hard cases:**
- **The omnibus trap (codebook V4, [real]).** A Yea on the One Big Beautiful Bill Act (2025), a
  reconciliation bill covering taxes, Medicaid, immigration and more → `multi-subject`. Statements
  that defend its **work requirements** ("sound policy") speak to a narrower clause than any rung →
  `adjacent`.
- **Medicaid work requirements** on their own → `adjacent` (same codebook example) _(proposed for the
  stand-alone case)_.
- **Budget resolutions and appropriations** that assume Medicare or Medicaid savings → V4
  `multi-subject`; a budget resolution's assumptions are not law _(proposed)_.
- **A multi-subject bill that includes drug price negotiation** (climate, tax and health together) →
  `multi-subject`. Only an amendment or a separate vote on the negotiation provision can carry rung 3
  [b] _(proposed)_.
- **Medicaid enrollment procedure** (renewals after the pandemic, paperwork, enrollment drives) does
  not change who is eligible → `adjacent` _(proposed)_.
- **A Medicare for All bill** can also be evidence on `healthcare`. Code each topic on its own rung
  text.
- **Preemption (codebook V2, H12)** → `adjacent`.


### topic_key: misinformation
topic_id: ddd65d64-9dc7-4208-a30f-59f4b9c0653d  served_revision_id: bd313c07-02a5-4344-8cc3-0e4b4c3b78a1
Question: What responsibility do platforms and government have in combating online misinformation?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: same-sex-marriage
topic_id: c5ab4eab-702f-49b8-9277-8ea53f3835c6  served_revision_id: 8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f
Question: What legal recognition should same-sex marriages receive?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: school-vouchers
topic_id: 00b95a6a-75db-4521-b523-3326bba938de  served_revision_id: 88858826-90c0-41c9-a3a4-1d9f5b8c5307
Question: What role should vouchers and school choice play in the public education system?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: social-security
topic_id: 87d20824-a6e9-407b-983c-65440084a0ab  served_revision_id: 8defc029-0b7e-426f-b838-a2e170f566c9
Question: How should Social Security be funded and structured for the future?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.
  2. increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.
  3. make small adjustments to both benefits and taxes to keep Social Security stable for future generations.
  4. gradually reduce future benefits rather than raise taxes to keep Social Security solvent.
  5. transition Social Security to private investment accounts that individuals control themselves.

#### Annex

# social-security — served revision 8defc029-0b7e-426f-b838-a2e170f566c9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Social Security be funded and structured for the future?"

**Orientation:** standard. Rung 1 is the largest public programme (bigger benefits, more tax), rung 5
replaces it with private accounts. The rungs order **benefit level and how it is paid for**. Rungs
1–4 each pair a benefit side with a tax side, so most of them are compound.

**Levels with a lever:** federal. Only Congress sets benefits and the payroll
tax. State and local officeholders hold no lever on any rung.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "OASDI", "trust fund", "solvency", "payroll tax", "FICA", "taxable maximum" or "wage
base cap", "donut hole", "full retirement age", "COLA", "CPI-E", "chained CPI", "progressive price
indexing", "minimum benefit", "WEP" and "GPO" (Windfall Elimination Provision, Government Pension
Offset), "personal accounts", "carve-out accounts", "fiscal commission".

1. **"expand Social Security benefits significantly and remove the income cap on payroll taxes to
   fund it."**
   - Means: benefits rise a lot for beneficiaries in general, paid for by taxing all earnings.
   - Operative clauses: [a] a significant benefit increase; [b] remove the payroll-tax cap; [c] the
     tax pays for the increase. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: authoring or co-sponsoring a single-subject bill that raises
     benefits broadly (an across-the-board increase, a higher COLA formula) **and** applies the
     payroll tax to earnings above the present cap.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A "donut hole" design (tax again above a threshold, with a gap below it) meets [b] "remove the
     income cap": no upper limit remains. The **size of the benefit increase** then separates rung 1
     from rung 2 _(ruled 2026-10-01)_.
   - Commonly confused with rung 2 because both raise taxes on higher earners. When the tax side does
     not separate them, the **size** of the benefit increase does: across-the-board → rung 1
     territory; one group or a small amount → rung 2 territory _(proposed)_.

2. **"increase Social Security benefits modestly while raising taxes on higher earners to strengthen
   the program."**
   - Means: a small benefit increase, paid for by more tax on high earners.
   - Operative clauses: [a] a modest benefit increase; [b] raise taxes on higher earners. Compound:
     one side only → `compound-partial`.
   - Establishing evidence looks like: a bill or own words with both a limited increase (a minimum
     benefit, a targeted increase) and a tax rise aimed at high earners.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - **[real] (codebook V6, H5).** Co-sponsoring the Social Security Fairness Act (WEP/GPO repeal, a
     benefit increase for one group, no tax side) plus "must be willing to reform" → BLANK
     `compound-partial`.

3. **"make small adjustments to both benefits and taxes to keep Social Security stable for future
   generations."**
   - Means: small changes on both sides, without a large cut or a large tax rise.
   - Operative clauses: [a] a small benefit adjustment; [b] a small tax adjustment. Compound (V4.2
     names this rung): one side only → `compound-partial`.
   - Establishing evidence looks like: a solvency bill or own words that name a change on each side
     (a small retirement-age or COLA change **and** a small payroll-tax or wage-base change).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a benefit-side change (raise the retirement age) is in
     both. Rung 3 needs a tax side; rung 4 needs the tax side **rejected**. A benefit change plus
     openness to a tax change → rung 3 territory; a benefit change alone → `compound-partial` for
     both _(proposed)_.

4. **"gradually reduce future benefits rather than raise taxes to keep Social Security solvent."**
   - Means: future benefits grow less or are cut over time, and taxes are not raised.
   - Operative clauses: [a] gradually reduce future benefits (a higher retirement age, chained CPI,
     price indexing, means-testing all count); [b] **rather than** raise taxes — the person rejects a
     tax rise for solvency. [b] must be stated (V4.2 "Silence is not a clause"). Compound: [a] only →
     `compound-partial`.
   - Establishing evidence looks like: a benefit-side solvency plan **plus** the person's own words or
     record against a tax rise.
   - A signed no-new-taxes pledge is `statement-answer` (codebook V3, H8) and can meet [b], in cycle
     (V5) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - S1 rung 4 was "raise the retirement age **and** reduce benefits for higher earners". The served
     rung adds [b] and drops the named mechanisms. S1 evidence on the retirement age alone now meets
     [a] only.
   - **[real] (codebook V6, H5).** A voter-guide answer for "gradually raising the retirement age" and
     a later "everything's on the table" (`rhetorical`) → [a] only, [b] unmet → BLANK
     `compound-partial`.

5. **"transition Social Security to private investment accounts that individuals control
   themselves."**
   - Means: the programme moves to accounts that each person owns and invests.
   - Operative clauses: [a] a transition of the programme to private accounts; [b] individual control.
   - Establishing evidence looks like: a bill or own words that move payroll-tax contributions into
     individually owned investment accounts in place of the benefit.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A voluntary carve-out of a small part of the payroll tax is a step, not a transition →
     `direction-only` _(proposed)_. Accounts **added** on top of Social Security (funded outside the
     payroll tax) → `adjacent` _(proposed)_.

**Hard cases:**
- **"Protect Social Security", "no cuts", "keep our promise"** exclude rungs 4 and 5 only →
  `direction-only`.
- **A fiscal or trust-fund commission bill** orders a report → V4 `study-directive`.
- **Income tax on benefits** (exempt benefits from income tax, a senior deduction) is not the payroll
  tax and not a benefit level → `adjacent` _(proposed)_.
- **Budget resolutions** that assume Social Security changes → V4 `multi-subject` _(proposed)_.
- **SSA administration** (field offices, staffing, phone wait times) → `adjacent`.
- **Ratings from seniors' groups** → V3 `not-evidence`; follow them to the roll calls.


### topic_key: tariffs
topic_id: 683c8084-2281-4920-a07c-18439b2dd413  served_revision_id: c9b67f92-c9b9-4f7e-a10b-c312a4219346
Question: How should trade policy balance domestic industry with global commerce?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: trans-athletes
topic_id: d1618b9c-0b9e-45af-b986-bb33d270b8e4  served_revision_id: c47c957a-5eb6-426f-b38d-89e44ba8fe73
Question: How should sports leagues determine eligibility for transgender athletes?
  1. allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.
  2. should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition.
  3. decide transgender athletes' eligibility case by case based on individual circumstances and the requirements of each sport.
  4. require transgender athletes to compete only on teams matching their biological sex assigned at birth.
  5. completely ban all transgender athletes from competing in any organized sports competitions.

#### Annex

# trans-athletes — served revision c47c957a-5eb6-426f-b38d-89e44ba8fe73 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`af2c6427-…`); coders code the served text below.

**Question:** "How should sports leagues determine eligibility for transgender athletes?"

**Orientation:** standard. Rung 1 lets every transgender athlete play on the team of their gender
identity with no conditions, rung 5 bars transgender athletes from all organised sport. The rungs
order **how far eligibility follows gender identity**: always, after documentation, case by case,
by sex at birth, not at all.

**Levels with a lever:** federal, local, state. The main lever is state law on
school and college sport. Congress acts through Title IX and federal bills. School boards set
district athletic policy where state law leaves room. Athletic associations are not officeholders;
an officeholder's vote on their rules is.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "Save Women's Sports", "Fairness in Women's Sports", "Protection of Women and Girls in
Sports Act", "biological sex", "sex at birth", "sex assigned at birth", "designated for females",
"girls' teams" or "women's teams", "coed" or "open" teams, "Title IX", "gender identity",
"testosterone threshold", "hormone therapy", "eligibility commission".

1. **"allow all transgender athletes to compete on teams matching their gender identity without any
   restrictions or requirements."**
   - Means: a transgender athlete plays on the team of their gender identity, and nothing more is
     asked.
   - Operative clauses: [a] all transgender athletes; [b] teams matching gender identity; [c] no
     restriction or requirement. [c] is an absence clause: the instrument or words must state it
     (V4.2 "Silence is not a clause").
   - Establishing evidence looks like: a law or policy that sets eligibility by gender identity and
     says no documentation or medical condition applies; own words saying so.
   - Levels that hold a lever: state; local; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A general gender-identity anti-discrimination law that covers school activities but says nothing
     about documentation does not meet [c] → `direction-only` _(proposed)_.
   - Commonly confused with rung 2 because a law can admit by gender identity and leave the
     documentation rules to an athletic association.

2. **"should allow transgender athletes to compete on teams matching their gender identity after
   completing basic documentation of their transition."**
   - Means: a transgender athlete plays on the team of their gender identity once they document their
     transition.
   - Operative clauses: [a] teams matching gender identity; [b] after basic documentation of the
     transition (a letter, a record of hormone therapy for a set time).
   - Establishing evidence looks like: a policy or own words that admit by gender identity on one
     uniform documentation condition.
   - Levels that hold a lever: state; local; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because hormone-level rules can be either. One condition for every
     sport → rung 2; conditions that differ by sport or are decided per athlete → rung 3
     _(proposed)_.

3. **"decide transgender athletes' eligibility case by case based on individual circumstances and
   the requirements of each sport."**
   - Means: no single rule; each athlete's eligibility is decided on their facts and their sport.
   - Operative clauses: [a] case by case on individual circumstances; [b] by the requirements of each
     sport.
   - Establishing evidence looks like: a law that sends eligibility to a body that decides per athlete
     and per sport; own words for that.
   - Levels that hold a lever: state; local; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - **Separate transgender divisions are no longer part of this rung** (S1 rung 3 had "create
     separate transgender divisions or …"). A separate-division or open-category proposal is not
     ordered by these rungs → `off-axis` _(proposed)_.
   - A sex-at-birth rule with a waiver or appeal process: code the rule the instrument enacts; a
     narrow waiver does not turn it into rung 3 _(proposed)_.

4. **"require transgender athletes to compete only on teams matching their biological sex assigned
   at birth."**
   - Means: an athlete plays on the team of their sex at birth, whatever their gender identity.
   - Operative clauses: [a] a requirement; [b] teams by sex at birth.
   - Establishing evidence looks like: authoring, sponsoring, or a final-passage vote on a
     **single-subject** bill that limits girls' or women's teams to students who are female at birth.
     The bill is narrow enough that a vote for it is chair-shaped (V4.1), if the tally is not
     near-unanimous.
   - **A girls'-teams-only law is rung 4.** Most such laws restrict only girls' and women's teams and
     leave boys' or coed teams open to all. That still reads as rung 4; rung 4 does not need the boys'
     side restricted too. Leaving boys' or coed teams open is also what excludes rung 5.
   - Levels that hold a lever: state; federal; local (district policy).
   - Known chair-shaped instruments: Utah HB11 (2022), barring transgender girls from girls' school
     teams (codebook V4.2, [real]: a vote to override the governor's veto); H.R. 28 (119th, 2025)
     (codebook V6, single-subject).
   - Commonly confused with rung 5: a sex-at-birth team rule is not a ban from sport.

5. **"completely ban all transgender athletes from competing in any organized sports competitions."**
   - Means: transgender athletes may not compete in organised sport at all.
   - Operative clauses: [a] all transgender athletes; [b] any organised sport; "completely" is an
     absence clause (V4.2).
   - Establishing evidence looks like: own words or an instrument that excludes transgender athletes
     from every team, including boys', coed and open teams.
   - Levels that hold a lever: state; federal; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Party inference (codebook V6, H2, [real]).** "Voted with the caucus on this party-line vote",
  with no roll call in the sources → every passage fails V1 → BLANK `no-evidence`. Fetch the roll
  call; for a single-subject bill it is then chair-shaped.
- **A governor's veto or signature** is a record. A signature on a single-subject bill is
  chair-shaped; a veto shows only a side unless the veto message names a rung → `direction-only`
  _(proposed)_.
- **A state law that sets the rule for every school** is the rule itself, not preemption. A law that
  only forbids school boards to set their own policy → `adjacent` (codebook V2, H12).
- **A federal resolution against a Title IX rule** that covers much more than athletics →
  `multi-subject` unless the vote is on the athletics provision _(proposed)_.
- **An amendment on the athletics provision** of a larger bill (for example a defence bill) can
  carry a chair (V4.1).
- **Budget and omnibus votes** → V4 `multi-subject`.


### topic_key: ukraine-support
topic_id: 24e9212c-b011-422a-865c-093e35050901  served_revision_id: 9ee7ecb7-fd99-429a-a37d-eff58a381983
Question: What level of military and financial support should be provided to Ukraine?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. significantly increase military and financial aid to Ukraine.
  2. continue providing current levels of military and economic aid to help Ukraine defend itself.
  3. provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.
  4. reduce aid to Ukraine and focus American resources on domestic priorities instead.
  5. end all aid to Ukraine immediately and stay completely out of the conflict.

#### Annex

# ukraine-support — served revision 9ee7ecb7-fd99-429a-a37d-eff58a381983 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`107d180d-…`); coders code the served text below.

**Question:** "What level of military and financial support should be provided to Ukraine?"

**Orientation:** standard. Rung 1 is the most support (a significant increase), rung 5 ends all aid.
The rungs order **how much aid**, and from rung 3 down, **what kind** (humanitarian only) and how far
the United States stays involved.

**Levels with a lever:** federal. Congress appropriates the aid and authorizes
transfers; state and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "supplemental appropriation", "security assistance", "Ukraine Security Assistance
Initiative" (USAI), "presidential drawdown authority" (PDA), "Foreign Military Financing" (FMF),
"direct budget support", "economic support", "lend-lease", "frozen Russian assets", "humanitarian
assistance", "ceasefire", "peace talks", "negotiated settlement".

1. **"significantly increase military and financial aid to Ukraine."**
   - Means: send substantially more military and financial aid than now.
   - Operative clauses: [a] a significant increase; [b] military and financial aid.
   - Establishing evidence looks like: own words that call for more aid, or for aid larger or faster
     than current packages; a bill or amendment that adds aid above what is in force.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - "Until complete victory" is no longer part of this rung. A war-aim statement without an amount
     → not evidence for or against rung 1 _(proposed)_.
   - "Military and financial aid" is one clause with two forms: more **military** aid alone is
     enough _(ruled 2026-10-01)_.
   - Commonly confused with rung 2: see rung 2.

2. **"continue providing current levels of military and economic aid to help Ukraine defend
   itself."**
   - Means: keep aid at about the level it has been, without a large increase or a cut.
   - Operative clauses: [a] continue aid; [b] at current levels; [c] military and economic aid.
   - Establishing evidence looks like: a Yea on a Ukraine-specific aid bill **plus** own words that
     frame it as keeping support steady, not raising it. A Yea alone excludes rungs 3–5 but not rung
     1 → `direction-only` (V4: chair-shaped must exclude the adjacent rungs) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because the rungs differ on **magnitude** ("current levels" vs
     "increase"). A Yea on a supplemental (H.R. 8035, 2024, codebook V4) does not show whether its
     size is "current" or an "increase" → BLANK `direction-only` without own words about the size
     _(ruled 2026-10-01)_.

3. **"provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end
   the war."**
   - Means: humanitarian help only, no weapons, and a push for talks to end the war.
   - Operative clauses: [a] limited humanitarian aid (and so no military aid); [b] encourage
     negotiations to end the war.
   - Establishing evidence looks like: own words or a record that support humanitarian aid while
     opposing military aid, **and** call for negotiations. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a call for talks is common **beside** support for military
     aid. Talks plus continued weapons is not rung 3 _(proposed)_.

4. **"reduce aid to Ukraine and focus American resources on domestic priorities instead."**
   - Means: cut aid, but not end it, and spend the money at home.
   - Operative clauses: [a] reduce aid; [b] direct the resources to domestic priorities.
   - Establishing evidence looks like: own words or an amendment that cuts aid and moves the money to a
     domestic purpose. Compound: one side only → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a Yea on a **cut** does not show the person wants some aid
     to stay. Sponsoring a partial cut sets the amount; voting for one does not exclude rung 5 →
     `direction-only` without own words _(proposed)_.

5. **"end all aid to Ukraine immediately and stay completely out of the conflict."**
   - Means: stop every kind of aid now, and take no part in the war at all.
   - Operative clauses: [a] end all aid; [b] immediately; [c] stay completely out of the conflict.
   - Establishing evidence looks like: own words or an amendment that strikes all Ukraine aid,
     **plus** own words against any other involvement. [c] is an absence clause (V4.2) → without
     it, `compound-partial`.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A **No** on an aid bill excludes rungs 1–2 only; it does not separate 3, 4 and 5 →
     `direction-only` (V4.1).

**Hard cases:**
- **Combined packages.** Ukraine aid inside a package with aid for other countries, border measures
  or other spending → V4 `multi-subject`; a Yea proves direction at most. The defense authorization
  bill → `multi-subject`.
- **Condemnation and solidarity resolutions** name no aid level → V4 `rhetorical` or `adjacent`.
- **Sanctions on Russia** and **use of frozen Russian assets** are not U.S. aid levels → `adjacent`
  _(proposed)_.
- **Oversight and audit measures** (an inspector general for Ukraine aid) say how aid is tracked,
  not how much → `adjacent` _(proposed)_.
- **Near-unanimous votes** (codebook V4) cannot carry the chair alone.


### topic_key: voting-rights
topic_id: d1792200-1d3b-4955-a0b7-0e6980d7a7b2  served_revision_id: 2a18c152-67a0-4380-a381-cb8795110a7c
Question: How should the government verify a voter's identity and eligibility?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Require no identification to vote, verifying voters by signature or existing records.
  2. Accept non-photo identification, such as a utility bill or bank statement.
  3. Require photo ID to vote, but let voters without one cast a ballot after signing an affidavit.
  4. Require photo ID in person and an ID number on every mail ballot.
  5. Require documentary proof of citizenship to register to vote.

#### Annex

# voting-rights — served revision 2a18c152-67a0-4380-a381-cb8795110a7c (Season 2)

**Status:** draft (2026-10-01 refresh of the 2026-09-26 draft). Lines marked _(proposed)_ are a
drafter's reading, not yet ruled; lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the government verify a voter's identity and eligibility?"

**Orientation:** standard. Rung 1 requires the least identification, rung 5 the most. Rungs 1–4
order **what identification a voter must show to vote**; rung 5 moves to **registration** and asks for
documentary proof of citizenship.

**Levels with a lever:** federal, state. The lever is state: election codes set
ID and registration rules. Federal law sets registration and mail-ballot rules for federal elections.
Local governments run elections but, in most states, cannot set their own ID rules.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "voter identification", "voter ID", "photo identification", "strict photo ID",
"proof of citizenship", "documentary proof of citizenship" (DPOC), "SAVE Act", "signature
verification", "signature match", "HAVA identification", "affidavit", "reasonable impediment
declaration", "provisional ballot", "cure", "ID number" (driver's licence number, last four digits of
the SSN).

1. **"Require no identification to vote, verifying voters by signature or existing records."**
   - Means: voters show no ID; officials check them against signatures or the records on file.
   - Operative clauses: [a] no ID at the polls; [b] signature or record matching instead.
   - Establishing evidence looks like: a bill that removes an existing state ID requirement; own words
     against any ID. [a] is an absence clause and must be stated (V4.2).
   - Levels that hold a lever: state; federal (federal elections).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 when the person only opposes **photo** ID.
   - Commonly confused with BLANK when the bill forbids **local** ID rules: that is preemption (see
     hard cases), not "require no identification".

2. **"Accept non-photo identification, such as a utility bill or bank statement."**
   - Means: an ID is required, and documents without a photo are accepted.
   - Operative clauses: [a] ID required; [b] non-photo documents accepted.
   - Establishing evidence looks like: a bill that widens the accepted list to non-photo documents; a
     bill that keeps a list with non-photo documents against a move to photo only.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK when a bill amends an existing ID law without setting what ID is
     required: the existing law's rung is not the person's position → BLANK `no-evidence`.

3. **"Require photo ID to vote, but let voters without one cast a ballot after signing an
   affidavit."**
   - Means: voters show photo ID, and a voter without one can still vote after signing a sworn
     statement.
   - Operative clauses: [a] photo ID required; [b] an affidavit fallback for voters without one.
   - Establishing evidence looks like: a photo-ID law with an affidavit or reasonable-impediment
     declaration that lets the ballot count _(proposed for the declaration)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 when the photo-ID law has **no** affidavit fallback. A provisional
     ballot that counts only if the voter brings ID later is not an affidavit → not rung 3; it is rung
     4 clause [a] only → `compound-partial` _(proposed)_.
   - Free-ID provisions are no longer part of any rung. They do not decide the chair _(proposed)_.

4. **"Require photo ID in person and an ID number on every mail ballot."**
   - Means: photo ID at the polls, and an ID number on each mail ballot.
   - Operative clauses: [a] photo ID in person; [b] an ID number on every mail ballot.
   - Establishing evidence looks like: a law, or two records, that cover both. Compound: one side only
     → `compound-partial` (V4.2).
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.

5. **"Require documentary proof of citizenship to register to vote."**
   - Means: a person must show a document that proves citizenship before they can register.
   - Operative clauses: [a] documentary proof of citizenship; [b] at registration.
   - Establishing evidence looks like: a proof-of-citizenship bill (for example the federal SAVE Act).
     A final-passage Yea on a single-subject proof-of-citizenship bill is `chair-shaped` without
     sponsorship (V4.1); check `near-unanimous`.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_. Code each record from its own bill text and
     roll call.
   - Commonly confused with rung 2 when the same bill also has weaker identity clauses. The
     documentary-proof clause is rung 5 verbatim; code it, not the weaker clauses beside it.
   - A rule for **registration** that is not documentary proof (an ID number, a database match, a
     sworn statement of citizenship) matches no rung → `direction-only` _(proposed)_.
   - The SAVE Act is rung 5 verbatim, but an encyclopedia page about it is not the person's act. Find
     the roll call or the sponsorship (codebook V1, V6, Kennedy / voting-rights).

**Hard cases:**
- **Preemption is not the rule (codebook V2, H12).** A bill that forbids local governments to require
  ID (California SB 1174, 2023-2024) decides *which level* may set the rule, not *what* the rule is →
  `adjacent`; BLANK `no-evidence` when nothing else survives. Three coders read it as rung 1, twice;
  only V2 catches it.
- **Ballots, not voters.** Rules about the ballot itself (paper, design, security marks, counting,
  tabulators) do not verify a voter → `adjacent`.
- **A mail-ballot rule with no identity clause** (drop boxes, deadlines) → `adjacent` (codebook V2).
- **A No vote** on an ID or proof-of-citizenship bill shows only that the person did not want that bill
  → BLANK `direction-only`.
- **Roll maintenance and eligibility** (removing inactive registrations, citizen-only voting
  amendments, non-citizen voting in local elections) do not set how identity is verified →
  `adjacent` _(proposed)_.
- **An omnibus election bill** that includes an ID clause → V4 `multi-subject`.


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


### topic_key: border-security
topic_id: 407614a8-ba2c-4145-8224-233655e6ac3f  served_revision_id: 76d9941b-3085-42cf-b229-ac41f4f85b8d
Question: How should the government handle people who cross the border?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Give everyone who crosses the border a fair asylum hearing.
  2. Expand orderly, legal ways to seek asylum at the border.
  3. Combine strong enforcement with a faster asylum process.
  4. Sharply restrict who can claim asylum at the border.
  5. End asylum and quickly turn back anyone who crosses illegally.

#### Annex

# border-security — served revision 76d9941b-3085-42cf-b229-ac41f4f85b8d (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the government handle people who cross the border?"

**Orientation:** standard. Rung 1 gives every person who crosses an asylum hearing, rung 5 ends
asylum and turns people back. The rungs order **how much access to asylum a person at the border
has**. Do not read the number as "more government": enforcement rises as the number rises.

**Levels with a lever:** federal. Asylum law, border enforcement and the
immigration courts are federal. State border measures (state troops, barriers, state crossing
crimes) do not decide who may claim asylum or how claims are heard; a state or local officeholder's
position on these rungs can be shown only by their own words.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "asylum", "credible fear", "expedited removal", "ports of entry", "between ports",
"parole", "CBP One" or "appointments", "Remain in Mexico" / "Migrant Protection Protocols", "safe
third country", "transit ban", "Title 42", "expulsion", "border emergency authority",
"asylum officers", "immigration judges", "backlog", "wall" / "barrier".

1. **"Give everyone who crosses the border a fair asylum hearing."**
   - Means: every person who crosses, wherever and however they cross, can ask for asylum and gets a
     full, fair hearing.
   - Operative clauses: [a] everyone who crosses, including between ports of entry; [b] a fair
     asylum hearing.
   - Establishing evidence looks like: own words that every person who crosses must get a hearing; an
     instrument that ends expedited removal or bars turning people back without a hearing.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because opposing a **restriction** reads like "a hearing for
     everyone". A No on a restriction shows the side only → `direction-only` (V4.1).

2. **"Expand orderly, legal ways to seek asylum at the border."**
   - Means: the government opens more lawful routes to ask for asylum at the border, such as more
     processing at ports of entry or appointments.
   - Operative clauses: [a] expand; [b] orderly, legal ways to seek asylum at the border.
   - Establishing evidence looks like: an instrument that adds processing capacity or lawful entry
     routes for asylum seekers, **plus** something that excludes rung 1 (own words that people who
     cross between ports should use the lawful routes) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: a new route does not say that everyone who crosses elsewhere
     still gets a hearing.
   - Commonly confused with rung 3 because more asylum officers also make the process faster. Rung 3
     needs the enforcement clause as well; capacity alone → `direction-only` _(proposed)_.

3. **"Combine strong enforcement with a faster asylum process."**
   - Means: more enforcement at the border, and quicker asylum decisions, together.
   - Operative clauses: [a] strong enforcement (agents, barriers, detention, removal of those who do
     not qualify); [b] a faster asylum process (more officers or judges, shorter time to decision).
   - Establishing evidence looks like: a single-subject border bill that does both. Compound: one side
     only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a faster process often comes with a **higher screening
     standard**. Code the eligibility rule: if the bill narrows who may claim, it reaches rung 4's
     clause; if it only speeds decisions, it is rung 3 _(proposed)_.
   - Border bills are often attached to foreign-aid supplementals → V4 `multi-subject`.

4. **"Sharply restrict who can claim asylum at the border."**
   - Means: many fewer people are allowed to ask for asylum at the border.
   - Operative clauses: [a] restrict eligibility to claim asylum at the border; [b] "sharply".
   - Establishing evidence looks like: an instrument that bars claims by large groups (people who
     crossed between ports, people who passed through another country) or that suspends claims when
     crossings exceed a number.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A narrow change (one category, one procedural bar) is not "sharply" → `direction-only`
     _(proposed)_.
   - Commonly confused with rung 5 because a **suspension** of asylum claims reads like "end
     asylum". A suspension that applies only while crossings stay above a set number restricts asylum
     → rung 4, not rung 5 _(ruled 2026-10-01)_.

5. **"End asylum and quickly turn back anyone who crosses illegally."**
   - Means: no asylum claim is available, and anyone who crosses unlawfully is sent back at once.
   - Operative clauses: [a] end asylum; [b] quickly turn back anyone who crosses illegally.
   - Establishing evidence looks like: own words or an instrument that does both. An expulsion
     authority that removes crossers without asylum screening meets [b]; [a] still needs the passage
     to say asylum is ended, not paused. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Barriers and personnel.** Money for a wall, agents or technology is enforcement only → rung 3
  clause [a] at most; it does not say what happens to asylum claims → `direction-only` _(proposed)_.
- **Where claimants wait** (a rule that makes claimants wait outside the country) restricts the
  process, not who may claim → `direction-only` _(proposed)_.
- **People already inside the country** are the `deportation` question. A passage about removal of
  long-settled people → `adjacent` here _(proposed)_.
- **Legal immigration levels** (visas, refugee caps) are not on this ladder → `adjacent`.
- **Budget, appropriations and supplemental votes** with a border item → V4 `multi-subject`.
- **Resolutions** that condemn a border policy, or that praise agents, name no clause → V4
  `rhetorical`.


### topic_key: education-curriculum
topic_id: 6c43fdec-d084-415d-a15d-d78f48d4fb34  served_revision_id: 2146e080-bd5e-4e1e-8a51-fcc1b44af916
Question: How should schools handle contested topics like race, gender, and history in what they teach?
  1. Require lessons that center race, gender, and social justice as themes across the curriculum
  2. Teach an honest account of racism, injustice, and diverse identities as part of the core curriculum
  3. Present contested social and historical topics as open questions, giving competing viewpoints equal weight
  4. Keep the curriculum focused on core academics and leave contested social topics to families
  5. Prohibit lessons on race, gender, or sexuality that the community considers divisive or age-inappropriate

#### Annex

# education-curriculum — served revision 2146e080-bd5e-4e1e-8a51-fcc1b44af916 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools handle contested topics like race, gender, and history in what they
teach?"

**Orientation:** off-axis. Both ends are mandates: rung 1 **requires** lessons on these themes and
rung 5 **prohibits** some of them; rung 4 is the least prescriptive. The rungs order **how much room
the curriculum gives these topics**, from centring them everywhere to forbidding them — not the
amount of government action.

**Levels with a lever:** local, school, state. The lever is state standards
and statute, and the school board's curriculum adoption and instruction policy. A city or county
council holds no curriculum lever unless it runs the school system _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "academic standards", "social studies standards", "ethnic studies", "culturally
responsive", "divisive concepts", "critical race theory" (CRT), "prohibited concepts", "parental
rights in education", "age-appropriate", "instructional materials", "curriculum transparency",
"opt-out", "diverse and contending perspectives".

1. **"Require lessons that center race, gender, and social justice as themes across the curriculum"**
   - Means: every subject must build its lessons around race, gender and social justice.
   - Operative clauses: [a] a requirement; [b] race, gender **and** social justice as central themes;
     [c] across the curriculum, not in one course or unit.
   - Establishing evidence looks like: a statute, standard or board policy that requires these themes
     to be integrated in all or most subjects; own words calling for that.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a required **course** (for example an ethnic-studies
     graduation course) adds the content in one place. It does not meet [c] → rung 2 territory, and
     it needs rung 2's evidence _(proposed)_.

2. **"Teach an honest account of racism, injustice, and diverse identities as part of the core
   curriculum"**
   - Means: the required curriculum teaches the history of racism and injustice, and diverse
     identities, as fact, not as an optional extra.
   - Operative clauses: [a] content on racism, injustice and diverse identities; [b] in the core
     (required) curriculum; [c] taught as an honest account, not as an open question.
   - Establishing evidence looks like: a standard, statute or adopted course that requires this
     content in core subjects. To exclude rung 1, the passage must not require the themes across the
     whole curriculum; to exclude rung 3, it must not order equal weight for competing views.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a mandate to teach **one historical subject** (for example
     a required unit on a named historical injustice) points toward this rung but is narrower than "racism, injustice, and diverse
     identities" → `direction-only` (V4.2 "Broader than the instrument").

3. **"Present contested social and historical topics as open questions, giving competing viewpoints
   equal weight"**
   - Means: teachers present these topics as unsettled and give each side the same weight.
   - Operative clauses: [a] contested topics presented as open questions; [b] competing viewpoints
     given equal weight.
   - Establishing evidence looks like: a "balanced perspectives" provision — teachers who discuss a
     contested topic must present it from competing perspectives without favouring one.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because one act often carries a balance clause **and** a list of
     prohibited concepts. Code the provision the passage relies on. An act that prohibits named
     lessons is rung 5 territory when rung 5's clauses are met; a balance clause beside the
     prohibition does not move it to rung 3. Rung 3 needs an instrument or own words that ask for
     balance **instead of** a ban _(proposed)_.

4. **"Keep the curriculum focused on core academics and leave contested social topics to families"**
   - Means: schools teach core academic subjects and do not teach contested social topics; families
     deal with them at home.
   - Operative clauses: [a] focus on core academics; [b] contested social topics left to families.
   - Establishing evidence looks like: own words that state both clauses; a policy that removes
     contested social topics from instruction **without** a prohibition list (a prohibition is
     rung 5).
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both keep topics out. Rung 5 forbids named lessons; rung 4
     does not ask for a ban. A ban → rung 5, not rung 4.
   - "Back to basics" or "focus on reading and math" alone meets [a] only → `compound-partial`.

5. **"Prohibit lessons on race, gender, or sexuality that the community considers divisive or
   age-inappropriate"**
   - Means: some lessons on race, gender or sexuality are forbidden because they are judged divisive
     or not suitable for the students' age.
   - Operative clauses: [a] a prohibition on lessons; [b] on race, gender **or** sexuality (one is
     enough); [c] because they are divisive or age-inappropriate.
   - Establishing evidence looks like: operative text that forbids instruction on named concepts, or
     on gender identity or sexual orientation in named grades.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - "The community" is the public acting through its elected body: a state statute's own list of
     prohibited concepts meets it, as does a board policy. The text must still prohibit the lessons
     and give a divisiveness or age reason _(ruled 2026-10-01)_.

**Hard cases:**
- **State law and school boards.** A state law that itself forbids or requires instruction in every
  public school states the rule → `on-question`. A law that only moves the decision (for example
  "only the state board may adopt …", or "a district shall not require a teacher to …" with no rule
  on what is taught) decides which level decides → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Curriculum transparency** (posting materials online, parent review of materials) and
  **opt-out** rights → `adjacent`. They let parents see or decline a lesson; they do not set what
  is taught _(proposed)_.
- **Sex-education rules** (abstinence, consent, opt-in) → `adjacent` unless the operative text
  forbids or requires lessons on gender or sexuality as such _(proposed)_.
- **Book and library challenges** → `adjacent` (they have their own topic).
- **Budget or omnibus votes** with a curriculum item → V4 `multi-subject`.
- **A study, task force or standards review** → `study-directive`.


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


### topic_key: education-gender-identity
topic_id: d96f987e-3404-4667-909d-5889116ba6e5  served_revision_id: 89f9d4a5-362e-4470-9529-46d4826fdeb9
Question: What should schools do when a student uses a different name or gender identity at school than at home?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Use the student's chosen name and pronouns, and keep their gender identity from parents unless the student agrees to share it
  2. Use the student's chosen name and pronouns, and tell parents only if they directly ask
  3. Tell parents when a student changes their name or gender at school, unless staff believe it would put the student in danger
  4. Require staff to notify parents whenever a student asks to be treated as a different gender at school
  5. Require written parental permission before staff use a student's chosen name or pronouns

#### Annex

# education-gender-identity — served revision 89f9d4a5-362e-4470-9529-46d4826fdeb9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What should schools do when a student uses a different name or gender identity at
school than at home?"

**Orientation:** standard. Rung 1 gives the student's wish the most weight against disclosure to
parents; rung 5 gives parents a veto before staff act. The rungs order **who controls disclosure and
consent**: the student, the parent on request, the school with a safety exception, the school with
no exception, the parent in advance.

**Levels with a lever:** school, state. The lever is the school board's
policy and the state statute or state-board rule. A city or county council holds none →
own words only there _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal, local (codebook V2 "No-lever level").

**Synonyms:** "chosen name", "preferred name", "pronouns", "social transition", "gender support
plan", "parental notification", "parental rights", "forced outing", "parental consent", "safety
exception", "education records", "student privacy".

1. **"Use the student's chosen name and pronouns, and keep their gender identity from parents unless
   the student agrees to share it"**
   - Means: staff use the student's name and pronouns, and do not tell parents unless the student
     consents — even when a parent asks.
   - Operative clauses: [a] staff use the chosen name and pronouns; [b] no disclosure to parents
     without the student's consent. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that requires staff to use the chosen
     name **and** forbids disclosure without the student's consent.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both use the name. Rung 1 keeps the identity from a parent
     who asks; rung 2 answers a parent who asks. A policy that does not say what happens when a
     parent asks cannot separate them → `direction-only`.

2. **"Use the student's chosen name and pronouns, and tell parents only if they directly ask"**
   - Means: staff use the student's name and pronouns, do not notify parents on their own, but answer
     truthfully when a parent asks.
   - Operative clauses: [a] staff use the chosen name and pronouns; [b] no notice unless a parent
     asks; [c] disclosure when a parent asks. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy with no notification duty that releases the
     information on a parent's request.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - A general parent right to see education records does not by itself meet [b] or [c]; it does not
     say what staff do about name or gender → `adjacent` _(proposed)_.

3. **"Tell parents when a student changes their name or gender at school, unless staff believe it
   would put the student in danger"**
   - Means: the school tells parents by default, but staff may hold back when they believe telling
     would endanger the student.
   - Operative clauses: [a] a notification duty; [b] a safety exception that staff apply.
   - Establishing evidence looks like: a notification statute or policy with an exception for a
     belief that disclosure would cause abuse, neglect or harm.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

4. **"Require staff to notify parents whenever a student asks to be treated as a different gender at
   school"**
   - Means: staff must notify parents every time, with no safety exception.
   - Operative clauses: [a] a notification duty; [b] it applies whenever a student asks.
   - Establishing evidence looks like: operative text that makes notification a duty on every such
     request and carries no safety exception. A duty stated for every request is a stated rule, not
     silence.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the safety exception is in another section of the same act or
     in a cross-referenced law. Read the whole act: an exception anywhere in it → rung 3.
   - Commonly confused with rung 5 when the act also requires consent. Notice only → rung 4; consent
     before use → rung 5.

5. **"Require written parental permission before staff use a student's chosen name or pronouns"**
   - Means: staff may not use the chosen name or pronouns until a parent gives written permission.
   - Operative clauses: [a] parental permission; [b] in writing; [c] before staff use the name or
     pronouns.
   - Establishing evidence looks like: operative text that requires written parental consent for
     the use of a different name or pronouns.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Permission that need not be written meets [a] and [c] only → `compound-partial` _(proposed)_.
   - A rule that forbids staff to use a name or pronouns that do not match sex **even with** parental
     permission is past this rung, and no rung states it → `direction-only` _(proposed)_.

**Hard cases:**
- **A law that forbids school boards to adopt a notification policy** (or a law that forbids them to
  adopt a confidentiality policy) removes one side's rule statewide, but it does not itself require
  the other side's practice → `on-question` but `direction-only` (V2 "Refined 2026-09-26") _(proposed)_.
- **Teacher speech protections** (a teacher may not be required to use a pronoun) → `adjacent`
  _(proposed)_.
- **Sports, restrooms and locker rooms** → `adjacent` (sports has its own topic).
- **Curriculum on gender identity** → `adjacent` (curriculum has its own topic).
- **Federal law** (education-records rights, Title IX rules) is not a role here; a state or school
  passage that only cites it → `adjacent` unless it states the school's own rule _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


### topic_key: education-equity-programs
topic_id: 66b389c7-86fc-45e9-bf34-964bb747f27b  served_revision_id: 23d87824-d25c-4b9a-8b13-fb2799d75661
Question: How should schools address gaps in achievement and opportunity between groups of students?
  1. Fund dedicated equity offices and staff to close gaps between student groups
  2. Require equity training for staff and set measurable goals to close gaps between groups
  3. Measure results for each student group and steer extra support to those falling behind
  4. Offer the same supports to every struggling student, without grouping them by race or identity
  5. Eliminate equity programs, training, and staff from the district

#### Annex

# education-equity-programs — served revision 23d87824-d25c-4b9a-8b13-fb2799d75661 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools address gaps in achievement and opportunity between groups of
students?"

**Orientation:** standard. Rung 1 is the most dedicated institutional effort (funded offices and
staff), rung 5 removes equity programmes. The rungs order **the mechanism used for gaps between
groups**: offices, training and goals, measurement and targeted support, the same support for every
struggling student, nothing.

**Levels with a lever:** local, school, state. The lever is the school board's
budget, staffing and policy, and state statute (mandates, bans, accountability rules). A city or
county council holds a lever only where it funds or runs the schools _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "equity office", "chief equity officer", "diversity, equity and inclusion" (DEI),
"achievement gap", "opportunity gap", "subgroup", "disaggregated data", "equity plan", "implicit-bias
training", "culturally responsive training", "targeted support", "multi-tiered system of supports"
(MTSS), "Title I".

1. **"Fund dedicated equity offices and staff to close gaps between student groups"**
   - Means: the district pays for an office and staff whose job is to close gaps between groups.
   - Operative clauses: [a] a dedicated equity office or staff; [b] funded; [c] with the purpose of
     closing gaps between groups.
   - Establishing evidence looks like: a single-item vote or resolution that creates or funds an
     equity office or position; own words calling for one.
   - Levels that hold a lever: school; state (a mandate on districts).
   - Known chair-shaped instruments: _(none on file)_.
   - A line item inside the annual budget → V4 `multi-subject`.

2. **"Require equity training for staff and set measurable goals to close gaps between groups"**
   - Means: staff must take equity training, and the district sets measurable targets for closing
     gaps.
   - Operative clauses: [a] required equity training for staff; [b] measurable gap-closing goals.
     Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that requires both.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because an equity plan often has both. Funding a dedicated office
     → rung 1; training and goals with no dedicated office → rung 2 _(proposed)_.
   - Commonly confused with rung 3 because goals and measurement look alike. A goal is a target;
     rung 3 is measurement plus support, with no training clause.

3. **"Measure results for each student group and steer extra support to those falling behind"**
   - Means: the district reports results by group and sends extra help to the groups whose results
     lag.
   - Operative clauses: [a] results measured for each student group; [b] extra support steered to
     groups that fall behind. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: an accountability rule that both reports by subgroup and
     directs support or intervention to the lagging groups.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Subgroup **reporting** alone (a common state or federal requirement) meets [a] only →
     `compound-partial`.
   - A funding weight for low-income or English-learner students steers money by category, not by
     measured results → `direction-only`, unless the act ties the support to the group's measured
     results. It is not rung 4 either: a weight treats groups differently _(ruled 2026-10-01)_.

4. **"Offer the same supports to every struggling student, without grouping them by race or
   identity"**
   - Means: help goes to each student who struggles, by individual need, and not by group.
   - Operative clauses: [a] supports for every struggling student by need; [b] no grouping by race
     or identity.
   - Establishing evidence looks like: own words or a policy that states both. [b] is an absence
     clause: the instrument must say it, for example by forbidding race- or identity-based
     eligibility for support (V4.2 "Silence is not a clause").
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a ban on group-based programmes often comes with a
     closure of equity offices. Rung 4 keeps support for struggling students; a ban that ends
     programmes and names no support for struggling students → rung 5 territory _(proposed)_.

5. **"Eliminate equity programs, training, and staff from the district"**
   - Means: the district ends its equity programmes, its equity training and its equity staff.
   - Operative clauses: [a] programmes ended; [b] training ended; [c] staff ended. Compound: some
     only → `compound-partial` _(proposed)_.
   - Establishing evidence looks like: a board resolution or statute that ends all three; own words
     calling for that.
   - Levels that hold a lever: school; state (a statewide ban that binds every district).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **State law and school boards.** A state law that bans (or requires) equity offices, training or
  programmes in every district states the rule → `on-question`. A law that only moves the decision
  to another body → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Admissions to selective schools or programmes** (test-based, lottery, geographic) → `adjacent`
  _(proposed)_.
- **Curriculum content on race or identity** → `adjacent` (curriculum has its own topic).
- **Discipline-disparity rules** (limits on suspensions) → `adjacent` _(proposed)_.
- **Study, audit or task force** on gaps → `study-directive`.
- **Annual budget votes** → V4 `multi-subject`.


### topic_key: education-school-police
topic_id: 15d7e730-119b-43a2-a351-1efb7352b86b  served_revision_id: d81d7662-3c68-425c-a5c6-ca0717384a9e
Question: What role should police officers play in schools?
  1. Remove police officers from schools and rely on counselors and mental health staff
  2. Keep officers out of schools and call them only when a serious crime occurs
  3. Bring in a shared or part-time officer with a limited, clearly defined role
  4. Place a dedicated officer in every school for safety, but bar them from routine discipline
  5. Place an officer in every school with authority to handle discipline and make arrests on campus

#### Annex

# education-school-police — served revision d81d7662-3c68-425c-a5c6-ca0717384a9e (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should police officers play in schools?"

**Orientation:** standard. Rung 1 removes officers from schools; rung 5 puts an officer in every
school with discipline and arrest authority. The rungs order **how much police presence and authority
schools have**.

**Levels with a lever:** local, school, state. The lever is the school board's
contract with a police agency (or its own district police), the city or county council that funds
and staffs the officers, and state statute (mandates, grants, limits on officers' role).

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "school resource officer" (SRO), "school safety officer", "school police department",
"memorandum of understanding" (MOU), "school-based law enforcement", "police-free schools",
"counselors not cops", "school-to-prison pipeline", "armed guard", "guardian programme".

1. **"Remove police officers from schools and rely on counselors and mental health staff"**
   - Means: schools have no police officers; counselors and mental health staff do the work instead.
   - Operative clauses: [a] officers removed; [b] reliance on counselors and mental health staff.
     Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a motion that ends the officer contract **and** moves the money
     or the duties to counselors or mental health staff; own words that state both.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both remove officers. A vote that only ends the contract
     separates neither rung → `direction-only`.

2. **"Keep officers out of schools and call them only when a serious crime occurs"**
   - Means: no officer is stationed in schools; police come only when a serious crime happens.
   - Operative clauses: [a] no officers stationed in schools; [b] police called only for serious
     crime. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy that ends stationed officers **and** sets a protocol
     that limits police calls to serious crimes.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Bring in a shared or part-time officer with a limited, clearly defined role"**
   - Means: an officer serves several schools or part of the time, under a written, limited role.
   - Operative clauses: [a] a shared or part-time officer; [b] a limited role that is written down.
   - Establishing evidence looks like: an MOU or contract for officers who cover more than one school
     or work part-time, with a defined scope of duties.
   - Levels that hold a lever: school; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a defined role also appears in dedicated-officer MOUs. The
     separator is coverage: one officer per school → rung 4.

4. **"Place a dedicated officer in every school for safety, but bar them from routine discipline"**
   - Means: each school has its own officer for safety, who does not handle ordinary student
     discipline.
   - Operative clauses: [a] a dedicated officer in every school; [b] the officer is barred from
     routine discipline. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a mandate or contract for an officer in every school **plus**
     operative text that excludes officers from routine school discipline.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A mandate for an officer in every school that is silent on discipline cannot separate rung 4
     from rung 5 → `direction-only` (V4.2 "Silence is not a clause").
   - A mandate with waivers (shared officers for small districts, or another person in place of an
     officer) does not meet "every school" → `direction-only` _(proposed)_.

5. **"Place an officer in every school with authority to handle discipline and make arrests on
   campus"**
   - Means: each school has an officer who may enforce school discipline as well as make arrests.
   - Operative clauses: [a] an officer in every school; [b] authority to handle discipline; [c]
     authority to make arrests on campus.
   - Establishing evidence looks like: a mandate or contract for an officer in every school whose
     duties include school discipline. Arrest power comes with a sworn officer; [b] must be stated
     _(proposed)_.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Armed staff or guards** who are not police (guardian programmes, armed teachers, private
  security) → `adjacent` _(proposed)_.
- **Grant programmes** that fund officers without a per-school rule → `direction-only` _(proposed)_.
- **Physical security** (cameras, metal detectors, locked entrances) → `adjacent`.
- **A city police budget** with an SRO line → V4 `multi-subject`; a single-item vote on the SRO
  contract → on-question.
- **State law and school boards.** A state law that itself requires or forbids officers in every
  school states the rule → `on-question`. A law that only decides which body may contract for
  officers → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Study, safety audit or task force** → `study-directive`.


### topic_key: education-charter-authorization
topic_id: c8807d3d-4264-47ce-b8c4-08c6c9c33ce3  served_revision_id: 3901e1b0-12b0-4f7e-9e14-061ae2247c26
Question: How should the board handle charter schools that want to open in the district?
  1. Stop authorizing new charter schools and move to close existing ones
  2. Approve new charters rarely, only when a school is clearly failing students
  3. Judge each charter application on its own merits
  4. Welcome charters and approve strong applications to expand family options
  5. Convert failing district schools into charters run by independent operators

#### Annex

# education-charter-authorization — served revision 3901e1b0-12b0-4f7e-9e14-061ae2247c26 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the board handle charter schools that want to open in the district?"

**Orientation:** standard. Rung 1 stops new charters and closes existing ones; rung 5 converts
district schools into charters. The rungs order **how readily charters are authorized**: none,
rarely, case by case, readily, by conversion.

**Levels with a lever:** local, school, state. The question is about the
board as authorizer. A school board holds the lever only where state law lets districts authorize;
state legislators set who may authorize, caps and conversion rules; a city holds a lever only where
the mayor or council is an authorizer _(proposed)_.

**Asked at:** state, local, school (`compass_topic_roles`, CA_0302).

**Synonyms:** "charter authorizer", "charter application", "charter petition", "charter renewal",
"charter cap", "moratorium", "state charter commission", "conversion charter", "restart",
"turnaround", "charter management organization" (CMO), "education management organization" (EMO),
"innovation school", "parent trigger".

1. **"Stop authorizing new charter schools and move to close existing ones"**
   - Means: no new charters, and the existing ones are wound down.
   - Operative clauses: [a] no new charters; [b] action to close existing charters. Compound: one
     side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a moratorium **plus** a non-renewal or closure plan for
     existing charters; own words that state both.
   - Levels that hold a lever: school (where it authorizes); state.
   - Known chair-shaped instruments: _(none on file)_.
   - Closing or not renewing **one** charter for its own performance is not [b] → `adjacent`
     _(proposed)_.

2. **"Approve new charters rarely, only when a school is clearly failing students"**
   - Means: new charters are the exception, approved only where students are clearly being failed.
   - Operative clauses: [a] approval is rare; [b] approval only where a school is clearly failing
     students.
   - Establishing evidence looks like: a policy or statute that limits new charters to areas or
     schools with documented failure.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - "A school is clearly failing" means the **district school the students would leave**, not the
     applicant _(ruled 2026-10-01)_.
   - Commonly confused with rung 1 because a moratorium with a failing-school exception blocks most
     charters. It allows some → rung 2 territory, not rung 1 _(proposed)_.

3. **"Judge each charter application on its own merits"**
   - Means: no presumption for or against charters; each application is judged on its quality.
   - Operative clauses: [a] case-by-case review; [b] no general presumption either way.
   - Establishing evidence looks like: own words that state merit review with no presumption; a
     policy of published quality criteria with no cap, moratorium or preference.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A vote on one application shows the person's act on that application, not a rule →
     `direction-only`. Approving some and denying others does not establish [b]: it rules out the
     ends, which is not evidence (V4.2 "Ruling out the other rungs").

4. **"Welcome charters and approve strong applications to expand family options"**
   - Means: the board favours charters and approves the strong ones to give families more choice.
   - Operative clauses: [a] a welcoming posture with the aim of more family options; [b] strong
     applications approved.
   - Establishing evidence looks like: own words that state both; a policy that sets expansion of
     charter options as a goal.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both favour charters. Lifting a cap or adding an
     authorizer does not say whether district schools should be converted → `direction-only`
     _(proposed)_.

5. **"Convert failing district schools into charters run by independent operators"**
   - Means: failing district schools are handed to independent charter operators.
   - Operative clauses: [a] conversion of failing district schools; [b] run by independent
     operators.
   - Establishing evidence looks like: a board vote to convert a named failing school to an
     independent operator; a statute that requires conversion as the consequence of failure.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A turnaround law that lists conversion as **one option** among several → `direction-only`
     _(proposed)_.

**Hard cases:**
- **Who authorizes.** A state law that moves authorization from districts to a state commission (or
  back) decides which body decides, and no rung is about that → `adjacent` (V2, H12).
- **Charter funding formulas and facilities access** → `adjacent` _(proposed)_.
- **Vouchers and ESAs** → `adjacent` (they have their own topic).
- **Charter accountability rules** (audits, renewal standards) → `adjacent` _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


### topic_key: education-school-budget
topic_id: 49f0b171-2ddf-4e68-887f-0ba78a2562f1  served_revision_id: 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc
Question: How should schools set spending levels and decide whether to raise more revenue?
  1. Raise taxes to significantly increase school funding
  2. Increase funding modestly to keep pace with costs, without raising taxes
  3. Hold funding flat at current levels
  4. Cut administrative overhead to lower costs while protecting classroom funding
  5. Cut school funding significantly to reduce the taxes residents pay

#### Annex

# education-school-budget — served revision 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools set spending levels and decide whether to raise more revenue?"

**Orientation:** standard. Rung 1 raises taxes to raise funding a lot; rung 5 cuts funding a lot to
cut taxes. The rungs order **the funding level and its tax source**. Rung 4 is about the **mix** of
spending (administration against classroom), not the level.

**Levels with a lever:** local, school, state. The lever is the school board's
budget and levy, the city or county council where it funds or approves the school budget, and the
state's school-aid formula and tax law.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "levy", "mill rate", "millage", "operating referendum", "override", "bond", "per-pupil
funding", "foundation amount", "school-aid formula", "adequacy", "truth in taxation", "levy limit",
"tax cap", "property-tax relief", "maintenance of effort", "central office", "administrative
overhead", "classroom spending".

1. **"Raise taxes to significantly increase school funding"**
   - Means: a tax increase that pays for a large rise in school funding.
   - Operative clauses: [a] a tax increase; [b] a significant funding increase. Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a vote to raise the levy or rate, or to put an operating
     referendum or override on the ballot, where the passage shows the increase is large.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - "Significantly" means an increase **above cost growth** (inflation and enrollment) as the
     passage shows; rung 2 defines "modestly" as keeping pace. A tax-funded increase that only keeps
     pace → `direction-only` (not rung 1: not significant; not rung 2: it raises taxes) _(ruled 2026-10-01)_.

2. **"Increase funding modestly to keep pace with costs, without raising taxes"**
   - Means: funding rises about as fast as costs, paid from existing revenue.
   - Operative clauses: [a] a modest increase that tracks costs (inflation, enrollment); [b] no tax
     increase. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget whose increase tracks costs **and** a levy or rate
     held at its current level. [b] is an absence clause: the passage must show no tax increase
     (V4.2 "Silence is not a clause").
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the nominal budget is flat but costs rise. Code the change
     the passage states; do not convert to real terms _(proposed)_.

3. **"Hold funding flat at current levels"**
   - Means: no increase and no cut.
   - Operative clauses: [a] the total stays at its current level.
   - Establishing evidence looks like: a budget or own words that keep the total the same as last
     year.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.

4. **"Cut administrative overhead to lower costs while protecting classroom funding"**
   - Means: spend less on administration and keep classroom spending whole.
   - Operative clauses: [a] a cut to administrative overhead; [b] classroom funding protected.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget amendment or own words that cut central-office or
     administrative spending **and** keep classroom spending at or above its level.
   - Levels that hold a lever: school; local; state (classroom-spending floors).
   - Known chair-shaped instruments: _(none on file)_.
   - A classroom-spending floor (a share that must go to instruction) meets [b] only →
     `compound-partial` _(proposed)_.

5. **"Cut school funding significantly to reduce the taxes residents pay"**
   - Means: a large funding cut that is made to lower taxes.
   - Operative clauses: [a] a significant funding cut; [b] made to reduce taxes. Compound: one side
     only → `compound-partial`.
   - Establishing evidence looks like: a vote to lower the levy or rate together with a large
     budget cut; own words that tie the two.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **Property-tax relief that the state replaces with state aid** lowers taxes without cutting
     funding → not [a] → `direction-only` _(proposed)_.

**Hard cases:**
- **A Yes on the district's annual budget** is `on-question`, not `multi-subject`: the total is this
  ladder's subject. It is chair-shaped only when the passage shows the year-over-year change and the
  levy or rate change; otherwise `direction-only` _(ruled 2026-10-01)_.
- **A No on a budget** proves nothing (V4.1).
- **What counts as raising taxes.** A higher rate, a higher levy amount, a new tax, or approval of a
  referendum, override or bond raises taxes. A rate held flat while values rise is not a tax
  increase unless the instrument says it raises the levy _(proposed)_.
- **Capital bonds** fund buildings, not operating spending → [a] at most; code [b] only when the
  passage ties the bond to the funding level _(proposed)_.
- **State levy limits and tax caps** on districts limit what a district may raise; they do not by
  their own text cut funding or lower a tax → `adjacent` (V2, H12), unless the act itself lowers
  rates _(proposed)_.
- **A state budget** with a school-aid line → V4 `multi-subject`; a single-subject school-aid bill →
  on-question.
- **Teacher pay and specific programmes** → `adjacent` unless the passage states the total level.


### topic_key: education-ai
topic_id: 61269f44-9c7f-4b27-818a-3508009f6ae2  served_revision_id: c6a2c643-aaa3-4d91-958e-e17f421b7dc9
Question: What role should artificial intelligence play in classrooms and student work?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Prohibit artificial intelligence tools in student work and classroom instruction
  2. Restrict artificial intelligence to teacher planning and administrative use, keeping it out of student work
  3. Permit students to use artificial intelligence on designated assignments, with disclosure required
  4. Encourage broad classroom use of artificial intelligence with light guidelines and teacher discretion
  5. Let teachers and students use artificial intelligence freely, without restrictions

#### Annex

# education-ai — served revision c6a2c643-aaa3-4d91-958e-e17f421b7dc9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should artificial intelligence play in classrooms and student work?"

**Orientation:** standard. Rung 1 prohibits AI in schools, rung 5 allows it with no restriction. The
rungs order **how much classroom and student use is allowed**: none, staff only, designated
assignments with disclosure, broad use with light rules, free use.

**Levels with a lever:** school, state. The lever is the school board's
policy (acceptable use, academic integrity, device and network rules) and state statute or
state-board rules. A city or county council holds none → own words only there _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal, local (codebook V2 "No-lever level").

**Synonyms:** "generative AI", "large language model", "chatbot", "AI tutor", "acceptable use
policy", "academic integrity", "AI disclosure", "AI literacy", "AI guidance", "responsible use".

1. **"Prohibit artificial intelligence tools in student work and classroom instruction"**
   - Means: AI is banned both from what students produce and from teaching in class.
   - Operative clauses: [a] banned in student work; [b] banned in classroom instruction. Compound:
     one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that bans AI tools for students **and** for
     classroom instruction.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A ban on student use that is silent on teachers cannot separate rung 1 from rung 2 →
     `direction-only`.
   - **Blocking AI sites on district networks and devices** is a ban in practice for students; it
     says nothing about instruction → [a] only _(proposed)_.

2. **"Restrict artificial intelligence to teacher planning and administrative use, keeping it out of
   student work"**
   - Means: teachers and staff may use AI for planning and administration; students may not use it
     for their work.
   - Operative clauses: [a] staff use allowed for planning and administration; [b] no student use.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy that permits staff use **and** bars student use.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Permit students to use artificial intelligence on designated assignments, with disclosure
   required"**
   - Means: students may use AI only where the assignment allows it, and must say when they did.
   - Operative clauses: [a] student use only on designated assignments; [b] disclosure required.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: an academic-integrity or acceptable-use policy with both
     clauses.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A disclosure or citation rule with no limit to designated assignments meets [b] only →
     `compound-partial`.

4. **"Encourage broad classroom use of artificial intelligence with light guidelines and teacher
   discretion"**
   - Means: schools promote wide use of AI in class, with a few rules and room for each teacher to
     decide.
   - Operative clauses: [a] broad use encouraged; [b] light guidelines; [c] teacher discretion.
   - Establishing evidence looks like: a policy or own words that promote classroom use and leave
     the limits to teachers under general guidance.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because teacher discretion can include "designated" assignments.
     If the policy requires disclosure and limits use to assignments the teacher designates → rung 3.

5. **"Let teachers and students use artificial intelligence freely, without restrictions"**
   - Means: no limits on AI use by teachers or students.
   - Operative clauses: [a] free use by teachers and students; [b] no restrictions.
   - Establishing evidence looks like: own words or a policy that rejects any restriction. [b] is an
     absence clause: a district with no AI policy has not said "no restrictions" (V4.2 "Silence is
     not a clause").
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because broad use with few rules reads like free use. Any
     guideline at all → not rung 5.

**Hard cases:**
- **A state law that requires each district to adopt an AI policy**, without saying what it must
  contain, decides that districts decide → `adjacent` (V2, H12) _(ruled 2026-10-01)_.
- **State guidance, task forces and pilot programmes** → `study-directive`.
- **Teaching about AI** (AI literacy, computer science standards) is not use in student work →
  `adjacent` _(proposed)_.
- **Student data privacy** rules for AI vendors, and **AI-generated images** of students (deepfakes)
  → `adjacent`.
- **Buying an AI tutoring product** → `direction-only` toward rungs 3–5 _(proposed)_.
- **Phone or device bans** that do not name AI → `adjacent`.
- **Budget or omnibus votes** → V4 `multi-subject`.


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


### topic_key: defense-spending
topic_id: 3fd1aa81-e032-4335-8785-452ed10ce9ce  served_revision_id: 5b75a7a2-1a72-436f-be9a-e60cf9ffada5
Question: How much should the government spend on the military?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Increase military spending substantially, launching a major buildup to expand the armed forces and their capabilities.
  2. Increase military spending moderately, growing the budget above inflation to keep pace with rising threats.
  3. Hold military spending roughly flat, allowing it to rise only with inflation.
  4. Reduce military spending modestly below current levels.
  5. Cut military spending dramatically, roughly halving the budget or more.

#### Annex

# defense-spending — served revision 5b75a7a2-1a72-436f-be9a-e60cf9ffada5 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How much should the government spend on the military?"

**Orientation:** standard. Rung 1 is the largest budget (a major buildup), rung 5 the deepest cut
(about half or more). The rungs order **the size of the military budget measured against
inflation**. How the money is spent, and where forces are based, are not on this ladder.

**Levels with a lever:** federal. Congress sets the budget through the annual
defense authorization and defense appropriations bills, budget resolutions and spending caps.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "national defense" (budget function 050), "topline", "base budget", "NDAA" (National
Defense Authorization Act), "defense appropriations", "budget request", "real growth",
"inflation-adjusted", "constant dollars", "percent of GDP", "spending caps", "sequestration",
"continuing resolution", "readiness", "procurement", "end strength", "force structure".

1. **"Increase military spending substantially, launching a major buildup to expand the armed forces
   and their capabilities."**
   - Means: a large real increase that grows the size and capability of the forces.
   - Operative clauses: [a] a substantial increase; [b] a major buildup that expands the forces and
     their capabilities.
   - Establishing evidence looks like: own words that call for a large increase (for example a much
     larger share of GDP) **and** for more forces or capabilities; an amendment that adds a large sum
     above the request for that purpose.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both increase. "Substantial" and "major buildup" separate
     them; an increase the passage does not size → `direction-only` _(proposed)_.

2. **"Increase military spending moderately, growing the budget above inflation to keep pace with
   rising threats."**
   - Means: steady real growth, above inflation but short of a buildup.
   - Operative clauses: [a] a moderate increase; [b] above inflation.
   - Establishing evidence looks like: own words that call for real growth (for example "3 to 5
     percent above inflation"), or an instrument whose topline the passage itself compares with
     inflation. Clause [b] needs that comparison in the snapshot; the coder does not supply an
     inflation figure _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **nominal** increase can be flat or a cut in real terms.
     Without the comparison → `direction-only` _(proposed)_.

3. **"Hold military spending roughly flat, allowing it to rise only with inflation."**
   - Means: keep the budget the same in real terms.
   - Operative clauses: [a] roughly flat; [b] rising only with inflation.
   - Establishing evidence looks like: own words for a freeze in real terms; a single-subject cap that
     limits defense growth to inflation.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A spending cap inside a debt-limit or budget deal that also caps other spending → V4
     `multi-subject`.

4. **"Reduce military spending modestly below current levels."**
   - Means: a small cut from what is spent now.
   - Operative clauses: [a] reduce; [b] modestly (a small share, for example around a tenth
     _(proposed)_).
   - Establishing evidence looks like: sponsorship of an amendment that cuts the topline by a modest
     share — sponsorship sets the amount (V4.1) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a **Yea** on a modest cut does not show the voter wants no
     deeper cut. Voting for it without own words → `direction-only` _(proposed)_.

5. **"Cut military spending dramatically, roughly halving the budget or more."**
   - Means: cut the budget by about half or more.
   - Operative clauses: [a] a dramatic cut; [b] about half or more.
   - Establishing evidence looks like: own words or an instrument that names a cut of about half or
     more. "Slash the Pentagon budget" with no size → `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **The annual defense authorization and defense appropriations bills.** Final passage →
  `multi-subject` _(ruled 2026-10-01)_. A **No** proves nothing (V4.1), and a Yea that the passage does not compare
  with inflation cannot separate rungs 2 and 3.
- **Topline amendments** (add or cut a stated sum or share) are the amendment row of the vote ladder
  (V4.1) and can carry a chair, but only when the size of the change maps to a rung's size
  ("substantially", "moderately above inflation", "roughly flat", "modestly below", "roughly
  halving") _(ruled 2026-10-01)_.
- **Composition is not size.** Moving money inside the budget (cancel one programme, fund another),
  pay raises, base closures, or an audit of the department → `adjacent` _(proposed)_.
- **Force posture** (where troops are based, whether to intervene) is the `military-intervention`
  question → `adjacent`. Aid to another country is `ukraine-support` or `israel-military-aid`.
- **Veterans' benefits** are not military spending on this ladder → `adjacent` _(proposed)_.
- **Reconciliation, omnibus and continuing-resolution votes** with a defense item → V4
  `multi-subject`. A continuing resolution that holds spending at last year's level is not own
  evidence for rung 3 _(proposed)_.


### topic_key: military-intervention
topic_id: 710396dc-e618-4011-8118-43c62a786111  served_revision_id: c42b12b6-d7c3-4b88-a932-06b87d5043c9
Question: How should the United States use military force abroad?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Use US military power to actively lead and police conflicts around the world.
  2. Intervene militarily when clear US interests or allied nations are directly threatened.
  3. Prefer diplomacy and economic sanctions, using military force only as a last resort.
  4. Avoid overseas military action except to defend US territory from direct attack.
  5. Withdraw from overseas military commitments and end foreign military intervention.

#### Annex

# military-intervention — served revision c42b12b6-d7c3-4b88-a932-06b87d5043c9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the United States use military force abroad?"

**Orientation:** standard. Rung 1 is the most use of force (lead and police conflicts worldwide),
rung 5 the least (withdraw from overseas commitments). The rungs order **the conditions under which
force is used abroad**, and at rung 5, whether the overseas footprint stays.

**Levels with a lever:** federal. Congress declares war, authorizes force,
funds deployments and can direct the removal of forces; state and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "War Powers Resolution", "authorization for use of military force" (AUMF),
"declaration of war", "hostilities", "deployment", "troop withdrawal", "forward presence",
"overseas bases", "collective defense", "NATO Article 5", "treaty commitments", "deterrence",
"strike", "regime change", "sanctions", "restraint", "global leadership".

1. **"Use US military power to actively lead and police conflicts around the world."**
   - Means: the United States uses force to shape and settle conflicts worldwide, not only where its
     own interests are threatened.
   - Operative clauses: [a] actively lead and police conflicts; [b] around the world.
   - Establishing evidence looks like: own words that the United States should act militarily in
     conflicts generally, as a world role.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because support for **one** strike or deployment reads like a world
     role. One use of force does not state a general rule → `direction-only` _(proposed)_.

2. **"Intervene militarily when clear US interests or allied nations are directly threatened."**
   - Means: force is used when U.S. interests or allies face a direct threat, and not otherwise.
   - Operative clauses: [a] intervene militarily; [b] when clear U.S. interests or allies are directly
     threatened.
   - Establishing evidence looks like: own words that state that condition as the test; a Yea on an
     authorization of force against a named direct threat **plus** words that tie it to the threat
     _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because rung 3 also allows force. Rung 3 tries diplomacy and
     sanctions first; rung 2 acts when the threat is direct. A passage that does not say which comes
     first → `direction-only` _(proposed)_.

3. **"Prefer diplomacy and economic sanctions, using military force only as a last resort."**
   - Means: diplomacy and sanctions come first; force only when they have failed.
   - Operative clauses: [a] prefer diplomacy and sanctions; [b] force only as a last resort.
   - Establishing evidence looks like: own words that state both. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A **sanctions bill** shows [a] at most; it is silent on force → `compound-partial` _(proposed)_.

4. **"Avoid overseas military action except to defend US territory from direct attack."**
   - Means: no military action abroad unless U.S. territory is attacked directly; defending allies is
     not an exception.
   - Operative clauses: [a] avoid overseas military action; [b] except to defend U.S. territory from
     direct attack.
   - Establishing evidence looks like: own words that limit force to defense of U.S. territory.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both oppose intervention. Rung 4 keeps the overseas
     footprint and does not use it; rung 5 pulls it back. A passage against one intervention that is
     silent on bases and commitments → `direction-only` _(proposed)_.

5. **"Withdraw from overseas military commitments and end foreign military intervention."**
   - Means: bring forces home, leave military commitments abroad, and stop intervening.
   - Operative clauses: [a] withdraw from overseas commitments (bases, deployments, alliances); [b]
     end foreign military intervention.
   - Establishing evidence looks like: own words or an instrument that withdraws from commitments
     generally. A bill to withdraw troops from **one** country meets [a] for that country only →
     `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **War Powers votes.** A resolution that directs the removal of forces from named hostilities is
  against **that** use of force; it does not state the general rule the rungs differ on →
  `direction-only` at most. A War Powers or authorization vote framed only as **who decides**
  (Congress or the President) → `adjacent` _(ruled 2026-10-01)_.
- **Authorizations of force** (AUMF) for one conflict → `direction-only`; a repeal of an old
  authorization that is no longer used → `adjacent` _(proposed)_.
- **Military aid and arms sales** are the `ukraine-support` and `israel-military-aid` questions;
  **the size of the budget** is `defense-spending` → `adjacent`.
- **The defense authorization bill** and other omnibus votes → V4 `multi-subject`.
- **Statements about one strike** ("the strike was right", "the strike was wrong") → `direction-only`
  unless the passage states the rule behind it _(proposed)_.


### topic_key: gun-policy
topic_id: 56125933-b82a-46c5-847b-b2e9a146b89f  served_revision_id: 44615418-e111-4f2f-a256-92fcf74b0f2f
Question: How should the government regulate firearms?
  1. Ban civilian firearm ownership, except for tightly licensed hunting and sport use.
  2. Ban semi-automatic assault-style weapons, while allowing other firearms.
  3. Allow all types of firearms, but require universal background checks on every sale.
  4. Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines.
  5. Repeal major gun restrictions and let adults carry a firearm without a permit.

#### Annex

# gun-policy — served revision 44615418-e111-4f2f-a256-92fcf74b0f2f (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled …)_ carry an operator ruling (Chris Andrews).
Lines marked _(proposed)_ are a drafter's reading, not yet ruled. No `_owed:_` line is open. The season pin is an older revision (`1a72d5df-…`); coders code the
served text below.

**Question:** "How should the government regulate firearms?"

**Orientation:** standard. Rung 1 is the most restriction (a ban on civilian ownership), rung 5 the
least (repeal major restrictions, carry without a permit). The rungs order **how far the law
restricts which firearms civilians may own, buy and carry**. Each person sits at the furthest line
they would go: someone who wants universal checks **and** an assault-weapons ban wants more than
rung 3 allows ("all types"), so sits at rung 2.

**Levels with a lever:** federal, local, state. The lever is state and federal
law. Most states forbid local gun ordinances, so a local lever exists only where state law allows one.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "assault weapon", "assault-style", "semi-automatic", "large-capacity magazine",
"universal background checks", "private sale", "gun-show loophole", "transfer", "concealed carry",
"permitless carry" / "constitutional carry", "reciprocity", "National Firearms Act" (NFA),
"suppressor", "red flag" / "extreme risk protection order", "safe storage", "ghost gun".

1. **"Ban civilian firearm ownership, except for tightly licensed hunting and sport use."**
   - Means: civilians may not own firearms, apart from tightly licensed hunting and sport guns.
   - Operative clauses: [a] ban civilian ownership; [b] the only exception is tightly licensed hunting
     and sport use.
   - Establishing evidence looks like: own words or an instrument that bans civilian ownership in
     general. A ban on one class of firearm is not this rung.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: a broad assault-weapons ban is still a ban on one class.

2. **"Ban semi-automatic assault-style weapons, while allowing other firearms."**
   - Means: assault-style semi-automatic weapons are banned; other firearms stay legal.
   - Operative clauses: [a] ban semi-automatic assault-style weapons; [b] allow other firearms.
   - Establishing evidence looks like: a single-subject assault-weapons ban. A ban written as a
     definition or list of the banned weapons meets [b]: the definition is the boundary, and the
     instrument leaves other firearms legal.
   - A bill that extends an existing assault-weapons ban to more weapons → rung 2.
   - Levels that hold a lever: federal; state; local where state law allows.
   - Known chair-shaped instruments: the Assault Weapons Ban of 2025 (S.1531 / H.R.3115), named in the
     topic note _(proposed: chair-shaped as filed)_.
   - A **magazine-capacity limit** alone is not a ban on a class of weapon → `direction-only`
     _(proposed)_.

3. **"Allow all types of firearms, but require universal background checks on every sale."**
   - Means: no type of firearm is banned, and every sale, private sales included, needs a background
     check.
   - Operative clauses: [a] allow all types of firearms; [b] universal background checks on every
     sale.
   - Establishing evidence looks like: a universal-checks bill **plus** evidence that the person
     opposes bans on a type of firearm (a No on an assault-weapons ban, own words). [a] must be shown;
     a checks bill is silent on bans (V4.2 "Silence is not a clause"). Compound: one side only →
     `compound-partial`. Not finding a ban cosponsorship is not evidence for [a] (H14) _(ruled 2026-10-01)_.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_. The Background Check Expansion Act (S.3214),
     named in the topic note, meets [b] only.
   - Checks for some sales only (gun shows, buyers under 21) are not "every sale" → `direction-only`
     _(proposed)_.

4. **"Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across
   state lines."**
   - Means: keep current gun laws, with no new limits; the furthest change is easier carrying, such
     as recognizing other states' carry permits.
   - Operative clauses: [a] no new restrictions; [b] at most, loosen carry rules (the major laws
     stay).
   - Establishing evidence looks like: own words against new restrictions, and a record that loosens
     carry rules without repealing major laws. The 4 / 5 line is whether the major laws stay _(ruled
     2026-09-08)_.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_. The Constitutional Concealed Carry Reciprocity
     Act (S.65 / H.R.38), named in the topic note, meets the "loosen carry" part of [b].
   - A reciprocity bill as the only record → BLANK `direction-only`. It meets the "loosen carry"
     part of [b], but one loosening law cannot show "at most" (V2, 2026-09-26) or "no new
     restrictions" (V4.2). Seat rung 4 only with a second passage: own words, or a recorded vote
     against a new restriction or against a repeal. This replaces the 2026-09-08 seating rule _(ruled 2026-10-01)_.
   - Not finding a rung-5 record is not evidence for rung 4 (V4.2 "Ruling out the other rungs").

5. **"Repeal major gun restrictions and let adults carry a firearm without a permit."**
   - Means: repeal the major gun laws, and let adults carry with no permit.
   - Operative clauses: [a] repeal major gun restrictions; [b] permitless carry for adults.
   - Establishing evidence looks like: a repeal of a major restriction (for example the federal NFA
     rules on suppressors or short-barrelled rifles, a state registration or assault-weapons ban)
     **and** permitless carry _(proposed)_. Compound: one side only → `compound-partial` (V4.2). For a
     state officeholder, see the state rule below.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **For a state officeholder**, a state law that removes the state's license or permit to carry
     meets **both** clauses: the carry license is the major restriction the state controls → rung 5.
     **For a federal officeholder**, [a] still needs repeal of major federal laws; a federal
     permitless-carry or reciprocity measure alone → `compound-partial` _(ruled 2026-10-01)_.

**Hard cases:**
- **Rules about how guns are stored, marketed or advertised** (safe storage, advertising to minors)
  do not say which guns may be owned or who may buy them → V2 `adjacent`; BLANK `no-evidence` when
  nothing else survives. A Yea and a No on such a bill are the same: the direction of the vote does
  not make it on-question.
- **Red-flag laws, waiting periods, minimum ages, ghost-gun rules** restrict but do not match a rung
  clause → `direction-only` _(proposed)_.
- **Preemption (codebook V2, H12).** A state law that voids local gun ordinances decides which level
  may act → `adjacent`.
- **Budget and omnibus votes** with a firearms item → V4 `multi-subject`.


### topic_key: israel-military-aid
topic_id: 6783e65c-0722-45d9-8579-65327af7c15c  served_revision_id: a9e300f1-8d13-4e34-89f0-e321031676b2
Question: What level of military aid should the U.S. provide to Israel?
Evidence basis at this seat's level (local): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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

(no codable sources — every row is BLANK no-evidence, with needs_source where you can name one)