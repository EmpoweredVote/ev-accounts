You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-military-intervention/labels/coder-3.json. Write JSON only, matching
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

### topic_key: military-intervention
topic_id: 710396dc-e618-4011-8118-43c62a786111  served_revision_id: c42b12b6-d7c3-4b88-a932-06b87d5043c9
Question: How should the United States use military force abroad?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


## Sources

---
snapshot_id: 2a51b6f1-86e6-5695-a18b-1ffd0ce662c5
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california

Saved from https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california (rendered page text, built-in browser, 2026-10-07) POLICY A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA ← POLICY ARCHIVE A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA Steve Hilton’s Plan to Stop Wildfires Before They Become Disasters THE PROBLEM Wildfires are no longer rare emergencies in California. They are a permanent threat. Every year, families lose their homes, communities are torn apart, insurance becomes more expensive or disappears entirely, and billions of dollars are spent reacting after the damage is done. We grieve, we rebuild slowly, and then we wait for the next one. This is not inevitable. Fire is part of California’s natural environment. Catastrophic fire is not. The scale and frequency of today’s disasters are the result of human choices, policy failures, and a system built around reaction instead of prevention. California does not lack firefighters, courage, or money. What we lack is a serious prevention strategy. WHY THE CURRENT APPROACH ISN’T WORKING California’s wildfire policy is reactive by design. It is built to mobilize after catastrophe, not to prevent it. That design did not happen by accident. It is the product of one-party Democratic rule in California, which has dominated state government for more than a decade and shaped how wildfire policy is written, funded, and enforced. Under Democratic control, the state has: Prioritized emergency reactivity and press conferences over long-term prevention. Made forest and brush management slower, more expensive, and harder to do through permitting, lawsuits, and extremist environmental regulation. Failed to deploy modern early detection systems, even as the technology has become affordable and reliable. Diverted fire spending towards growing government programs instead of reducing risk on the ground. Left homeowners and communities to navigate fire hardening on their own, with little support and lots of red tape. Allowed insurance risk to grow unchecked instead of reducing it through prevention. The system rewards reaction and paperwork. It punishes prevention. As a result, California has built a wildfire policy that looks busy but does not actually reduce risk. Fires keep getting bigger, more destructive, and more expensive even as spending keeps rising. That is what Democrat one-party rule produces: more bureaucracy, more process, more spending, and worse results. THE PLAN As governor, Steve Hilton will flip the model from reaction to prevention, making California the first place in the world where wildfire prevention is universal, modern, and proactive. Statewide Detection and Technology Deployment. Deploy modern detection and suppression technology statewide and reform procurement and regulatory rules so California can actually use and scale these tools quickly. A Modern Fire Force. Create a focused California Fire Force dedicated to early detection, rapid suppression, and deployment of modern technology including drones, automated systems, and advanced monitoring. End the Regulatory Barriers That Make Fires Worse. Roll back and reform extreme environmental and air quality regulations that have been weaponized to block basic fire prevention and firefighting. This includes fixing harmful air quality bureaucracy that has been used to stop controlled burns, reforming endangered species rules that prevent effective vegetation management and emergency response, and restoring common-sense authority for fire agencies to act. This will be achieved through executive orders and appointments of serious, results-driven leadership to key agencies like CARB, the Santa Monica Mountains Conservancy, and related regulatory bodies. Universal Fire Protection for Homes. Every home in a fire risk zone becomes eligible for state-supported fire prevention treatments. This is not a mandate. It is an incentive-driven system that makes prevention easy, affordable, and normal. These treatments include fire-retardant coatings for vegetation, decks, fences, and structures; ember-resistant upgrades and defensible space treatments; and modern non-toxic fire suppression and retardant technologies. Align Insurance With Prevention. Reform insurance regulation so insurers can and must offer meaningful premium discounts for fire-hardened homes and co-fund prevention programs, because preventing losses costs less than paying for disasters. Reward Fire Safety. Provide property tax credits for homeowners who complete certified fire prevention upgrades and streamline permits so people can protect their homes quickly. Fix Emergency Readiness and Response. Launch an immediate and comprehensive review, reporting within 90 days, of fire and emergency response capacity in high-risk counties and major cities to ensure the devastating failures exposed in Los Angeles under Mayor Karen Bass never happen again. This includes reviewing water availability and infrastructure, including reservoirs and hydrants, equipment readiness, personnel deployment, and inter-agency coordination. Steve Hilton will appoint an Emergency Preparedness and Response “A Team” of world-class professionals to lead this effort and set new statewide standards for readiness, coordination, and accountability. Open the Door to Innovation. Reform state procurement rules so California can actually use modern detection, suppression, and prevention technologies instead of blocking them with bureaucracy. This plan is informed by the work of Rick Crawford, former Los Angeles Fire Department Battalion Chief, whose California All-Risk Governance Doctrine documents the leadership, infrastructure, and coordination failures exposed by the Palisades Fire. His analysis reinforces the need to shift from reactive response to permanent, accountable readiness before the next disaster strikes. WHAT THIS WOULD MEAN FOR CALIFORNIANS Fewer fires would become disasters because early detection and suppression would stop fires while they are still small. Homes would be safer because fire-hardened properties would be far more likely to survive. Insurance would become affordable again because lower risk would mean lower premiums and more insurers willing to operate in California. Communities would be more stable with fewer evacuations, fewer rebuilds, and fewer families displaced. Taxpayer money would be spent smarter, because prevention costs a fraction of emergency response and rebuilding. Together, these changes would restore something Californians have lost: confidence that their government is actually working to keep them safe. ← Back to all policies

---
snapshot_id: e4c327be-c737-54d8-b709-656e04809002
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD ← POLICY ARCHIVE KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD THE PROBLEM California leads the world in artificial intelligence today. But decisions being made in Sacramento risk driving this critical industry out of our state. After 16 years of one-party rule, the pattern is clear: more regulation, higher taxes, and greater political control. That approach has already pushed other industries out of California—and now it is being applied to one of the most important technologies of the future. This is not just about jobs or investment. Artificial intelligence is a foundational technology with major national security implications. The global race is happening now, largely between the United States and China. If California weakens its position, America’s leadership is weakened with it. At the same time, California is failing to prepare its own people for the changes AI will bring. Educational outcomes are declining despite increased spending: Only 47% of students meet basic English standards Only 35% meet basic math standards These failures leave millions unprepared for a more technical, fast-changing workforce. California risks pushing out the industries of the future while failing to prepare its workforce to participate in them. WHY THIS IS HAPPENING This problem stems from a governing approach that prioritizes regulation, restriction, and taxation over growth. California policymakers approach new technologies with excessive caution rather than confidence. Instead of supporting innovation, they impose sweeping rules before technologies are fully developed. At the same time, the state has neglected foundational systems: Schools focus on bureaucracy over outcomes Workforce training and vocational pathways are limited There are fewer clear routes into skilled, well-paying jobs AI also depends on physical infrastructure and reliable energy—areas where California has struggled due to high costs, supply constraints, and regulatory delays. THE THREAT California is already seeing the consequences of this approach. Proposed legislation would: Restrict how AI can be developed and used Increase liability under vague standards Add new layers of bureaucracy Examples include: AB 1979: restricting AI use in healthcare SB 420: imposing liability for “algorithmic discrimination” SB 813: creating a new AI regulatory commission These proposals risk slowing innovation, pushing investment elsewhere, and increasing government control over technology. Combined with proposals like taxing unrealized gains, these policies threaten the foundation of California’s startup ecosystem. Unless direction changes, it will become easier for innovators to build the future somewhere else. THE PLAN 1. EXTEND CALIFORNIA’S GLOBAL LEADERSHIP IN AI California must be the best place in the world to build, invest, and grow AI companies. That requires: A strong business climate Affordable infrastructure A well-educated workforce Government should enforce basic accountability—but avoid sweeping, preemptive regulation on evolving technologies. 2. SET CLEAR, COMMON-SENSE GUARDRAILS There are real risks, but solutions should be targeted and practical. Focus areas include: Protecting children Preventing fraud and impersonation Safeguarding intellectual property and identity The approach should: Enforce existing laws Close clear gaps Avoid vague, open-ended rules 3. COMPETE FOR THE FULL STACK OF AI JOBS California must capture the entire AI ecosystem, including: Energy Manufacturing Infrastructure Computing Software and applications Right now, many of these jobs are going elsewhere due to cost and regulatory barriers. Fixing this means: Faster approvals Lower barriers to building A clear commitment to growth 4. DELIVER ABUNDANT ENERGY AND INFRASTRUCTURE AI depends on reliable, affordable energy. California must shift from scarcity to abundance by: Expanding in-state energy production Modernizing the grid Removing barriers to infrastructure development This includes: Utilizing existing natural gas capacity Expanding nuclear power over time Meeting rising electricity demand must be treated as an urgent priority. 5. PREPARE CALIFORNIANS TO WIN IN THE AI ECONOMY The most important role of government is preparing people—not controlling technology. Current education outcomes are failing students and the workforce. Key priorities include: Ensuring literacy and math proficiency Using phonics-based instruction Holding schools accountable for performance Students should not advance without mastering fundamentals. In addition: Expand vocational and technical education Support retraining for displaced workers Change is coming. The goal is to ensure Californians can move forward—not fall behind. CONCLUSION California has all the advantages needed to lead the world in artificial intelligence—but those advantages are being undermined by bad policy decisions. The state faces a choice: Continue down a path of overregulation, high costs, and declining outcomes or Prioritize growth, innovation, and opportunity If California gets this right, it will lead the AI revolution for decades to come . ← Back to all policies

---
snapshot_id: 53b1343d-b621-5bea-91ac-039d55e4a68e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/f3181318-9fab-49ea-a15f-44af7caa654d

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## Candidates for California governor race to convene in Fresno for forum - OTR page: https://ontherecord.empowered.vote/meetings/f3181318-9fab-49ea-a15f-44af7caa654d - Video: https://www.youtube.com/watch?v=TeE7gMPTgBo - Date on On the Record: 2026-04-01 - Kind: forum · Candidate Forum · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [10:57] Thank you very much, everybody. Thank you for hosting today. Thank you. Fresno State, it's great to be back at Fresno State. I first came here with my friend David Tangipa. It's so great to see him turn into this incredible champion for this area and for this great college. Um I started an organization 3 years ago called Golden Together to develop to develop solutions to the problems we face in California. The very first event was here in Fresno. I have spent so much time here getting to know all of you. I see so many friends out here today. As many of you know, cuz I've said it every time I've been here, my parents are Hungarian. Um I grew up in England, but they had the upbringing of a communist regime. And in our small town in Hungary at the south end of what is known as the great plain of Hungary, it is a deeply agricultural area. We had a small farm. You were only allowed a small farm cuz it was communism. But most of my career has been in business. Small business owner will be the designation on the ballot. And I know exactly what you've been going through, and I have to tell you, I think every single Democrat on this stage today should start with an apology. An apology for what their party has done to this area and this industry. Stealing your water, piling on the regulations, a thousand percent increase in the last decade or so, cutting the pay of agricultural workers. On and on, the assault on this industry has to stop, and they should start by apologizing for what they did. As your governor, you won't have a stronger champion for farming and for agriculture than me. On water, on the PAGA lawsuits that are destroying everyone's business, on labor regulations, on energy. We are going to get it done. I know what needs to be done. I've got the plan and the determination to do it. Thank you very much, everybody. [21:03] Mr. Houltin. Thank you. I'll stay seated for the questions. I think that um it is very clear what we need to get done. We do need to get rid of all the things that have made this the most expensive state in the country to live, to work, to run a business. Number one, we will cut vehicle registration. In most other states, vehicle registration under 100 bucks a year. Here, 600, 700, 800. Many of you may be paying over a thousand. On day one, we can stop that. Just a flat registration fee, $71 per vehicle per year. Number two, we will open up California oil and gas production so we can start to bring the cost of gas and diesel down for all of you and for everyone in California. My target, $3 gas. Number three, we will act on the regulatory burden that every single one of you faces. We can cut that so that we can cut costs so we don't have what we have now, the most expensive grocery bills in the country. Thanks to all the actions of this Democrat regime over 16 years of one-party rule. [27:33] you, Mr. Houltin. Thank you very much. And Katie, I do appreciate that you stole my tax plan for working people. I didn't steal your haircut, but eagle-eyed observers might see um if you look at my new profile pic on my social media today, on this very special day, I did steal somebody's haircut thanks to the wonders of AI. You can take a look at that after the debate. Um very quickly on energy, we I talked about my plan to get to $3 gas by opening up California oil and gas production. Electricity, the highest in the nation other than Hawaii. Why? Because of Democrat climate dogma. We have a fleet of gas-fired power stations in California today that are running at 10 to 15% capacity because they are only being used as backup for unreliable, more expensive wind and solar. That is insane when we have abundant gas reserves in California. We will use California natural gas to generate electricity to deliver my promise to cut your electric bills in half. [34:45] Two then? Yes, two, three. Every [40:56] >> [applause] >> So many of the points have been made correctly, but the honest truth is we're never going to reduce the cost of groceries or anything else until we abandon the climate dogma that has got us to this point. The Democratic Party has to abandon it clearly, decisively. No more. We're going to get rid of this insane net zero 2045 target that is driving the cost of energy up, that is driving the cost of gas, that is stopping affordable housing being built. We got to make a big decision here. Are we going to continue down the same path that's got us to this point or or are we going to take things in a new direction? And frankly, the people that got us to this point cannot possibly get it done because they are captured by the interests that drive costs up. The climate lobby, the unions, the trial lawyers that are driving all these things like PAGA lawsuits that are driving every business crazy. We have to have a complete break from the past or none of these promises from these Democrats will ever be delivered. [47:56] David Tangipa'u is in the house. Good to see you, man. How you doing? Um didn't you just see there revealed the arrogance of one-party rule? It's a blue state. We're going to be in power forever. You're just stuck with this. How outrageous, what contempt for the voters of this state. We have had enough. You've had enough. I've seen it all over the state. This state demands change and this is the year we're going to get it. Specifically on this great industry being crushed by these Democrat ideologues. Of course I want to save this industry. This is the greatest agricultural area in the world. When I'm governor, it will have everything it needs to thrive and flourish. We are going to make that happen. Top of the list, water. We are going to increase deliveries within the current infrastructure we have by deleting the biological assessments of recent years and increasing the water flow down here. We're going to dredge the Delta. We are going to finish those projects that should have been done years ago. Sites Reservoir. Finish the Folsom South Canal. Get the water you need to grow the healthy food that we need for our state and our nation. [50:17] better. What? What? You didn't say anything. [54:40] I love the way that people who've been power uh without restraint for 16 years keep telling us it's not partisan. Sorry, it's an election. It is partisan. It's a choice. Do we want to go the same direction or do we want to go in a new direction? On water, obviously, we need to go in a new direction. That direction is abundance in- instead of this forced scarcity driven by their climate dogma. So, let's go through the specific sec- again. Number one, we can increase deliveries within the current infrastructure without building anything extra by deleting the biological assessments of the State Water Resources Control Board. I will appoint people to do that. Number two, there is a simpler project that we can get done completing the Folsom South Canal that will immediately bring huge amounts of water from the Tuolumne and the American River into the uh four bay so it can get into the uh canals bringing water south without any much without building new dams, without doing any of that. These are practical things we can get done for low cost and get it done quickly. As your governor, that's what I would [56:53] >> three, we've heard more than we've [60:58] So, the artificial restriction of surface water is causing so many problems, not least because of the excessive pumping. You've now got subsidence under some of the water infrastructure. So, the canals are being broken and leaking and so the whole thing is being undermined. The answer to that is not to restrict further, it is to increase the deliveries of surface water, which we can do in the ways that I've I've outlined. In terms of the Delta, I'm sorry, but the Delta conveyance thing is a completely ridiculous project. It's the next high-speed rail. There's a very simple alternative. Thank you very much, which is to dredge the Delta so that we get faster flows and more flow out. Then you don't get the salt water incursion. In terms of the infrastructure, we've mentioned sites a couple of times. I want to complete the Folsom South Canal. We get huge amounts of water from those watersheds I mentioned, Tuolumne and American River, into our irrigation systems. And of course, one we haven't mentioned, raising Shasta Dam. All of these things we can do to increase the supplies of surface water. Then we don't need the restrictions of Sigma in terms of groundwater. [67:21] So, the original idea behind Sigma is correct. You because of um subsidence um driven by uh groundwater pumping, but the answer is to increase supplies of surface water. Then you don't need to deplete the resources and you can do groundwater recharge. So, all the things we've talked about in terms of increasing deliveries is actually the answer on Sigma. And actually, the other thing when you look at Sigma, it's just insanely complicated. The ridiculous bureaucracy, 500 plus of these agencies on top of the water districts and the other regulatory boards, it's all insane. It all needs to be cut back and shut down wherever possible. One other thing on water that's very important, the use of technology now. Um systems that can really do very accurate long-term rainfall casting and prediction. That means that we can manage the reservoir stocks better and the flows in and out of them. The Alice system, for example. There's so many things that we can do to get back to what we need, which is abundant water for our ag industry in the whole state. [74:06] So the most effective check on the power of agencies and regulators you've ever seen in this state will be me when I get there as governor and cut this insane, bloated, nanny state bureaucracy down to size. It is destroying opportunity in California in every single area and especially in the area that we're discussing today, our great ag industry. So of course we need to rein them in. The the only thing I would disagree with Matt over when he said earlier that he was going to get the bureaucrats out from behind their desks and into the Central Valley, I'd say yeah, I want to get them out from behind their desks and into the private sector to do productive work instead of endlessly clogging up the private sector with their ridiculous rules and regulations and nonsense. You will not see a more determined enemy of the bureaucracy than me when I'm governor and it's going to make a massive difference to everybody in every industry almost overnight. [88:16] >> [applause] >> Matt just talked about machinery. It reminded me of something. Um a while back, maybe a couple of years ago, I was out in the fields with for the pistachio harvest. That machinery was amazing to see. The shaking and the collecting, three different bits of machinery working together. And I was talking to the guys out there, and and one thing they said was, "You know what they're trying to do now? They're trying to turn this all electric. EVs for farm equipment." I said, "How is that going to work? We're out here in the middle of the field. How are we going to Where are we going to plug it in? What are we going to do?" And what that tells us is such an important story about what's been going wrong in California for all these years, because there with that story of trying to have electric vehicles in this insane manner, it's the triumph of ideology over practicality, forcing some intellectual, academic, ideological agenda onto real life for real people running real businesses and making their life a misery in the process. Now, I've run businesses most of my life, including in the food business, including restaurants. You've got to be practical. And that's what you'll get from me as your governor, a problem-solving, practical, business mindset. I've never run for office before. I'm I'm an outsider. I'm going to be going in there to shake up the system. And the last thing I'll say, just a few weeks ago I was down in Tulare for the World Ag Expo. What that showed me was just the magnificence of this industry and all the businesses and jobs that depend upon it, the pride of our state, the pride of our nation. And when I'm governor, this great industry, all your great communities will be supported like you've never seen before. Thank you.

---
snapshot_id: 72a5fa79-1885-5408-8307-31d8ed659512
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:14] >> Are we ready to save our beautiful state of [0:37] >> Democracy is under threat. >> Everyone agrees we need change. That's what I'm fighting for. [1:17] >> We can turn things around. You just have [7:39] >> So Caitlyn and Alex, it's interesting. We've already seen a couple of things that we'll probably see a lot of in this debate, which is the Democrats who are here who've been responsible for 16 years of one party rule for everything that we see in California won't take responsibility and all they can talk about is Trump. Look, I was asked how I'm preparing for this debate the other day. And my answer was the meetings, the thousands of people that have come to our events the last year in California. I've traveled to every part of the state. I've seen the struggle and the stories and that is my struggle and my stories. My parents were immigrants. The California dream is my dream and I want that for every single one of you watching out there. We can get it [8:39] >> So, they should vote for the candidate who's got a concrete plan to make our state calffordable. $3 gas, cut your electric bills in half, your first hundred grand taxfree, a home you can afford to buy. It's common sense, practical things. Most of my career has been in business. I know how to get things done. And we need to change. We need some fresh thinking. after 16 years of one party rule from these Democrats that have given us the highest poverty rate as you mentioned the highest unemployment rate and the highest cost of living in the country. [10:06] ahead. >> It's not Donald Trump who's given us gas prices $2 higher than the rest of the country. It's Democrat policies, which Antonia and all the Democrats here support. It's not Donald Trump that's given us the highest housing costs in the country. It's Democrat policies that all these Democrats support. Donald Trump is the president in all the other states of America where the cost of living is way lower than in California. Obviously, it is way past time for change in California and endlessly going on about Donald Trump doesn't serve the needs of the struggling families and small businesses. >> Can you say whether or not he won the election? [14:23] Hilton. >> So, so Matt says that it's obviously impossible to get to $3 gas. Um, as I have laid out in my plan, before the Iran war, there were 40 states in America with $3 gas or lower, most of the which don't have the abundant oil reserves that we have in California. But because of the policy supported by Matt and all these Democrats, we are now shipping oil halfway around the world, 7,500 miles from places like Iraq instead of opening up California oil and gas production so we can reduce costs and get $3 gas in California, which is my plan. [15:00] >> Secretary Bera. [24:05] >> It is. There's there's a very simple truth uh which everyone in California knows which is that taxes are too high and we need taxes to be lower and they're especially too high for working people in California. You got people on 70 80 90 grand in California which doesn't get you very far who are paying 9.3% state income tax. That is higher than the top rate in most other states. That's why my plan eliminates state income tax under 100 grand. And by the way, if you think that it can't get worse in California, I've got two words for you. Tom Styer. Under Tommy Styer, the taxes will be higher. Gas prices will be higher. Everything will be higher with Styer. [26:43] >> Thank you, [29:29] >> So I'm I'm the only immigrant on stage. I'm a legal immigrant and Americans support immigration when it is properly controlled. And what we saw under the Biden administration, open borders undermined everybody's support for immigration. And as governor, I've made it very clear although it is the federal government's responsibility to to um determine and implement immigration policy, I think it's important that all the laws are peacefully enforced. And as governor, I would make sure that we work with the federal government to enforce our laws. Expect [30:11] workers? >> The the policy on deportation is the exact same policy that we saw with President Obama. In fact, the numbers of deportations right now in our country and in California are slightly just to clarify your point. Can you answer the question? I answered the question which is I will work. >> Will you deport him? >> That was the question. >> Well, would you Antonia? Because the governor of California, as you know, doesn't make that decision. It is the president of the United States elected by the country. [34:43] >> I I don't want to respond to to silly name calling, but I'd like to actually respond to something Katie said, and I think it's probably a sincere policy um difference between us. She said something very revealing which is the only way really that California's economy has been growing in the last few years is through illegal immigration. And I just don't think that's the right way for us to be growing. I think we need to help small businesses create jobs and opportunity and for Californians to be able to earn more and live the California dream and for entrepreneurs to want to start businesses in California. That's how we should be growing our economy, not by [35:23] consequences of that decision, >> Katie, it's I there's a difference I think you'll accept between legal and illegal immigration. [43:18] Hilton, >> um Antonio mentioned uh me earlier and said I just recently arrived. It's true. I arrived here in 2012 with my wife and my two sons. But what's interesting is that um I don't think there's an appreciation of the difference between legal and illegal immigration. I've spent many many times right here in East LA where we are with legal immigrants with families of legal immigrants who really resent the unfairness that we're seeing in California where you have illegal immigrants who are getting free benefits, housing, welfare, and they say to me, "Look, we did it the right way. We worked hard. the right way. Candidates, don't worry. >> We are not getting fairness and we need to restore fairness in our [45:34] >> I think the next governor of California will have to work with the administration and with the president that the American people elected to get good results for Californians. And by the way, my attitude will be to work with the president regardless of party to get good results for Californians. Now, it so happens that we have a president who has endorsed me for governor, and we've discussed how I can work with his team to lower gas prices in California by opening up energy production, to reduce wildfire risk, by proper forest management, to get the fraud and the waste out of our state budget so we can cut taxes. These are all practical ways we can work together to help everyone. >> Thank you, Mr. California. [55:54] singlepayer healthcare. >> Just listen to these Democrats arguing about whether to go left or even further left when that's the direction that's got us into this mess, the highest cost, the highest taxes in the country. I'm the only person here with actual experience of singlepayer healthcare. Both as a patient and as a policy maker. As a patient, it nearly killed me. That's another story we don't have time for. As a policy maker, you end up with the worst patient satisfaction, cost that you can't afford, taxes skyhigh to pay for it. It is a total disaster. And the actual way we deal with health care in this state is to at least stop spending $20 billion a year on free health care for illegal immigrants who [64:17] Court has stopped you from being able to [64:21] that's a lie. My my view is that it's a bit rich for Javier to talk about following the law when he is mired personally in a corruption scandal where his former chief of staff Shan McCcluskey when Javier was appointed by Joe Biden to be health secretary he wanted his chief of staff to go with him. The salary wasn't enough. So what did they do? They took money from Javier's campaign account to top up his salary by funneling it to Dana Williamson, Gavin Newsome's former chief of staff, so that it was paid to this guy's wife. All of that is illegal. It is against state law. It's against federal law. My running mate for attorney general, Michael Gates, has this evening written to Javier Bera to make it clear that when he is attorney general, Javier will be investigated and if necessary, prosecuted for these crimes. [65:21] >> I'm not going to weigh in on something that I don't have the knowledge of the facts on. I trust that Chad is interested in what we should all be interested in, which is ensuring the integrity of our elections and restoring faith in our elections in California. That's why I support voter ID in California. Let's see what these Democrats think of voter ID. [66:24] chief And it was your decision. [66:29] Washington as health secretary and you wanted him by your side. And the reason that the money was transferred is because the salary wasn't high enough. That's why you engaged in this scheme which is [67:47] >> And just today, I launched a new plan for starter homes in California. One of the most heartbreaking things I see is young people, they come to our events and I asked them, "Do you ever see yourself owning a home in California, starting a family here?" And they say, "No, and we're going to have to leave." And that's why we've got to enact a very straightforward plan. Number one, we have to get rid of the regulations that make it two or three times as expensive to build the exact same home in California as in neighboring states. We have to stop the lawsuits filed by the unions who support these Democrats that get in the way of building housing. And to your point, we have to stop trying to force housing into suburban neighborhoods where people don't want it. Instead, we have to build single family homes in the places in our state that do want to expand. That's the plan to make sure that we can restore that California dream of home ownership. It is the heart of opportunity for our young people and it's being taken away by these Democrats and their policies. >> Mayor Mayanm, your response. [81:02] >> Mr. [81:04] Hilton, >> look, this is a very serious moment for California. The ballots are out. They're in your hands. And we have a really big choice to make, which is do we go for another four years of one party rule that's given us the highest taxes for the worst results, the highest poverty rate, highest unemployment rate, highest cost of living, serious policy questions, homelessness. We need to stop homelessness and end it. We need to stop funding fiascos like highspeed rail. We need to lift burdens on our business. That's what this debate needs to be about. And the only way to get the change we need is to [86:13] >> It's classic Democrats, isn't it? What you're hearing. Um, if it moves, tax it. If it still moves, regulate it. And if it stops, move it. I guess they want to subsidize it. Look, the truth is on this we have to have a bit of humility. This is a very fastmoving technology and actually even the people involved in it disagree about its exact consequences. Here are two things that we two practical things we could and should be doing better today. First of all, the real bluecollar jobs that are coming from the AI revolution, they're not happening in California. They're going to Texas and Arizona semiconductor manufacturing. We could get that back by removing regulations. And secondly, our school system is not educating our kids to be able to thrive in the world of AI. We need to [89:30] >> I think that was my word. Would you like [89:32] that charge? >> Again, I don't want to respond to silly insults, but I'll take the substantive point, which is first of all, when Tom talks about um uh tripling subsidies for electric vehicles, let's be clear what that is. That is higher taxes on hardworking Californians driving their gas, cars, and trucks every day so that Tom's rich friends can feel virtuous about saving the climate. The truth is, we need common sense on climate change. It doesn't make sense to import oil from halfway around the world, increasing carbon emissions in the name of climate. It doesn't make sense to allow mega wildfires in our forests that actually release more carbon dioxide than what is saved by all these climate policy. [96:06] Hilton. >> Um, so highspeed rail is an example of the fraud. Um, they've spent billions of dollars. I don't know where the money's gone. It certainly hasn't gone into building anything that actually works. And I just want to make one broader point about fraud. I'm actually running this race in a different way than we've seen before. I've put together a team to run with me. There are other statewide offices. And along with my running mate for state controller, Herb Morgan, and Michael Gates for attorney general, and Gloria Romero for Lieutenant Governor, we've actually been investigating the fraud. Our survey so far suggest that there in the last five years in California, we've had $425 billion dollars of fraud. That's around 80 billion a year, around 20% of the budget. And our team is going to stop it and prosecute it and give money. [96:54] >> real quickly, mayor. [99:59] I guess that would be a good one. [100:00] Clint Eastwood. >> Okay. Mr. Hilton. >> I think there's only one choice really. Jason [102:45] rest of the state? Well, um, if you ask my wife and my sons, often to their great embarrassment, it's that I absolutely hate bureaucracy and ridiculous, pointless rules and regulations that crush the life out of uh, people and businesses and daily experience that we have. And so, I just want to tell everyone, I'm going to be relentless, absolutely relentless in fighting the nonsense that makes life so difficult for each and every one of you. I will not rest until we restore sanity to our beautiful state of