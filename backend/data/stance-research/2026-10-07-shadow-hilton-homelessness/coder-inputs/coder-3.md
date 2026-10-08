You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-homelessness/labels/coder-3.json. Write JSON only, matching
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

### topic_key: homelessness
topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a  served_revision_id: 6958fa99-e317-45d7-8076-d11a0a78c897
Question: How should government address people sleeping or camping in public spaces?
  1. Protecting the right to sleep and shelter in public spaces, with no penalties of any kind
  2. Decriminalizing public sleeping and camping in public spaces
  3. Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system
  4. Prohibiting encampments on public property, enforced through graduated warnings and civil penalties
  5. Banning public camping and sleeping with criminal penalties to maintain public safety and order

#### Annex

# homelessness — served revision 6958fa99-e317-45d7-8076-d11a0a78c897 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-08-31)_ carry an operator ruling (Chris
Andrews, recorded with the chair-4 re-audit). Lines marked _(proposed)_ are a drafter's reading, not
yet ruled. Lines marked _(ruled 2026-10-01)_ carry a later ruling. No `_owed:_` line is open.

**Question:** "How should government address people sleeping or camping in public spaces?"

**Orientation:** standard. Rung 1 protects public sleeping with no penalty, rung 5 bans it with
criminal penalties. The rungs order **the penalty** for sleeping or camping in public: none, no
criminal penalty, enforcement only when shelter exists, civil penalties, criminal penalties.

**Levels with a lever:** federal, local, state. The lever is the local
ordinance and the state statute that sets or forbids camping rules. Federal officeholders act only on
federal land and through conditions on grants _(proposed)_.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "camping ban", "unauthorized camping", "public camping", "sit-lie", "encampment
sweep" / "clearance" / "abatement", "move-along order", "right to rest", "infraction",
"Class C misdemeanor", "citation", "diversion", "shelter-bed availability", "Martin v. Boise",
"City of Grants Pass v. Johnson" (2024).

1. **"Protecting the right to sleep and shelter in public spaces, with no penalties of any kind"**
   - Means: people may sleep and shelter in public spaces, and the law imposes no penalty of any
     kind for it.
   - Operative clauses: [a] a protected right to sleep and shelter in public; [b] no penalties of any
     kind, civil or criminal.
   - Establishing evidence looks like: a right-to-rest bill or ordinance that protects public
     sleeping and forbids fines and arrests for it; own words calling for both. [b] is an absence
     clause and must be stated (V4.2 "Silence is not a clause").
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because decriminalizing removes criminal penalties only. A measure
     that keeps a fine or a civil order is not "no penalties of any kind".
   - Housing and service spending is no longer part of this rung. A budget shift from enforcement to
     housing does not move a person to rung 1 → `adjacent` _(proposed)_.

2. **"Decriminalizing public sleeping and camping in public spaces"**
   - Means: sleeping and camping in public are no longer crimes.
   - Operative clauses: [a] remove criminal penalties for public sleeping and camping.
   - Establishing evidence looks like: a repeal of a criminal camping ordinance, or a vote against
     creating one; own words against criminal penalties for sleeping in public.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a law that turns a camping crime into a civil fine both
     decriminalizes (rung 2) and prohibits with civil penalties (rung 4). A law that turns a camping crime
     into a civil fine still prohibits, with a civil penalty → rung 4 (see the 2026-08-31 penalty-type
     ruling) _(ruled 2026-10-01)_.
   - A No on a criminal ban does not separate 1, 2, 3 and 4 → `direction-only`.

3. **"Allowing enforcement only when adequate shelter beds are available, with citations diverting
   people to services rather than the criminal justice system"**
   - Means: camping rules may be enforced only when a shelter bed is open, and a citation sends the
     person to services, not to court.
   - Operative clauses: [a] enforcement only when adequate shelter beds are available; [b] citations
     divert to services rather than the criminal justice system.
   - Establishing evidence looks like: an ordinance that conditions enforcement on an available bed
     **and** routes citations to services. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because many enforcement ordinances offer shelter first. An offer
     of shelter before a penalty is not [a] unless the law forbids enforcement when no bed is
     available _(proposed)_.

4. **"Prohibiting encampments on public property, enforced through graduated warnings and civil
   penalties"**
   - Means: encampments on public property are prohibited; enforcement starts with warnings and
     ends in civil penalties, not jail.
   - Operative clauses: [a] prohibit encampments on public property; [b] graduated warnings;
     [c] civil penalties.
   - Establishing evidence looks like: a camping prohibition whose penalty is a fine or other civil
     sanction, reached after warnings. A **fine-only Class C misdemeanor** is the civil tier → rung 4
     _(ruled 2026-08-31)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: Texas HB 1925 (2021), a statewide camping ban with a fine-only
     Class C misdemeanor, stayed on this rung in the 2026-08-31 re-audit. Check [b] in the text the
     person acted on.
   - Commonly confused with rung 5: the line is **penalty type**. Jail, arrest or prosecution → rung
     5; a fine only → rung 4 _(ruled 2026-08-31)_.
   - Shelter mandates are no longer part of this rung. A requirement to keep shelter beds does not
     move a person to rung 4 → `adjacent` _(proposed)_.

5. **"Banning public camping and sleeping with criminal penalties to maintain public safety and
   order"**
   - Means: public camping and sleeping are banned, and breaking the ban can lead to jail, arrest or
     prosecution.
   - Operative clauses: [a] ban public camping and sleeping; [b] criminal penalties. "To maintain
     public safety and order" is a purpose, not a clause the instrument must state _(proposed)_.
   - Establishing evidence looks like: a camping ordinance or statute with a misdemeanor that carries
     possible jail time, or that authorizes arrest.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: the Fremont camping ordinance (misdemeanor, up to $1,000 and six
     months in jail), Henderson Ordinance 3967, Colorado Springs Ordinance 26-08 (up to 10 days in
     jail); all moved to rung 5 in the 2026-08-31 re-audit.
   - Commonly confused with rung 4: see rung 4. Pairing a jail-backed ban with services, or saying it
     "does not criminalize", does not keep it at rung 4: the instrument's penalty decides _(ruled
     2026-08-31)_.

**Hard cases:**
- **Clearances and sweeps** with notice but no penalty on the person → `compound-partial` for rung 4
  (prohibition and warnings, no penalty clause) _(proposed)_.
- **Shelter, housing and outreach spending** with no penalty rule → `adjacent` (the
  homelessness-response topic covers funding).
- **Preemption (codebook V2, H12).** A state law that forbids cities to allow camping, or orders
  them to enforce a ban, decides which level acts → `adjacent`, unless the state law itself sets the
  penalty (then code that penalty) _(proposed)_.
- **Court rulings** (Martin v. Boise, Grants Pass) are not a person's act. Own words about a ruling
  count only when they name a penalty rule.
- **Budget and omnibus votes** with an enforcement item → V4 `multi-subject`.


## Sources

---
snapshot_id: 8ab4768c-411e-5630-ac44-a224dce6ba56
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: 60c26c43-77d5-58dc-909d-8601a565cbc4
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan

Saved from https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan (rendered page text, built-in browser, 2026-10-07) POLICY EMERGENCY ELECTION COUNT ACCELERATOR PLAN ← POLICY ARCHIVE EMERGENCY ELECTION COUNT ACCELERATOR PLAN INTRODUCTION California should be able to conduct elections that are both secure and timely. Every legal ballot should be counted, but voters should not have to wait weeks to find out the outcome of an election. The state routinely mobilizes personnel and resources during emergencies. When election offices face massive post-election backlogs, California should do the same. By temporarily assigning qualified state employees, deploying rapid-response support teams, and funding expanded county operations, California can accelerate ballot processing, reduce delays, and provide voters with election results more quickly while maintaining the integrity and security of the process. California is the fourth largest economy in the world, and home of the technology industry that has so dramatically changed the world. When it comes to elections, it’s time we acted like it. Ultimately, California needs broader reforms to its election system. But in the short term, for the primary election of June 2nd 2026, we cannot continue with a process that leaves millions of voters waiting weeks for results. Governor Newsom should immediately issue an emergency Executive Order designed to bring ballot-processing backlogs to a close as quickly as possible, with the goal of guaranteeing complete and verified election results within 48 hours of the deadline for receiving mail-in ballots: final election results by 8pm on Thursday 11th June. If India can count over 600 million ballots in 24 hours, surely California can count a tiny fraction of that number in twice the time. A SYSTEM THAT ISN’T WORKING California’s election delays are not an isolated problem. They are yet another symptom of a government that has stopped delivering basic results. Californians have been promised a high-speed rail project that has barely begun after years of delays and billions of dollars in spending. State and local governments have spent billions addressing homelessness while encampments remain a visible crisis in communities across the state. Now California once again finds itself waiting weeks for election results after fewer than ten million ballots were cast. It is an extraordinary and unacceptable shambles. California has become a global laughing stock for its inability to conduct elections in an efficient, timely manner. Californians have been conditioned to accept delays that would be unacceptable in almost any other area of government. Elections should be secure, accurate, and timely. The fact that voters can wait weeks for final results is evidence that the system is not functioning as it should. This is not about counting fewer ballots or lowering standards. It is about basic governing competence, which has completely collapsed in California, it now seems. Voters deserve an election system that is both accurate and efficient. PLAN FOR CHANGE California’s election laws should be reformed to deliver faster, more transparent, and more trustworthy election results. The following reforms would dramatically accelerate election results while preserving election integrity: Require vote-by-mail ballots to be received by Election Day rather than accepted for several days afterward if postmarked by Election Day. Mail ballots only to voters who specifically request them rather than automatically sending ballots to every registered voter. Provide free voter identification cards to all registered voters and require identification for in-person voting. Expand pre-election ballot processing so counties can verify signatures, prepare ballots for tabulation, and complete administrative review before Election Day. None of these reforms would eliminate the need to count every legal ballot. But together they would dramatically reduce post-election delays, improve transparency, strengthen confidence in the process, and move California toward a system where voters know the outcome of elections in hours, not weeks. EMERGENCY ELECTION COUNT ACCELERATOR CORPS While broader reforms are implemented, Governor Newsom should act immediately to accelerate the count in the primary election of June 2026. The Governor should establish an Emergency Election Count Accelerator Corps by temporarily deploying available state employees from non-essential administrative positions to county election offices experiencing significant ballot-processing backlogs. These personnel would work under the supervision of county Registrars of Voters and assist with ballot processing, administrative review, data entry, ballot preparation, and other support functions permitted under existing law. The state should also create regional election surge teams that can be rapidly deployed to counties facing the largest backlogs, ensuring staffing resources are directed where they are needed most. In addition, California should establish an Election Count Accelerator Fund to reimburse counties for overtime, expanded shifts, weekend operations, and other temporary costs associated with accelerating ballot processing after Election Day. The proposal would not change election laws, security procedures, or vote-counting standards. Every ballot would still be processed according to existing law and under the authority of local election officials. The goal is simple : count every legal ballot , maintain election integrity , and deliver timely results that voters can trust . Specifically , ensure that in the primary election of June 2026, Californians have complete and verified results within 48 hours of the deadline for receiving mail – in ballots . Final election results by 8 pm on Thursday 11 th June . ← Back to all policies

---
snapshot_id: f7dd06d7-a48c-5763-bd6a-b3075cf82f4c
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/operation-zero-waste

Saved from https://stevehiltonforgovernor.com/policies/operation-zero-waste (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE ← POLICY ARCHIVE OPERATION ZERO WASTE Cut waste. Cut bureaucracy. Pay for tax relief. INTRODUCTION California’s budget has more than doubled in the last ten years, from $170 billion to over $350 billion. Yet outcomes on every significant measure - from schools, to homelessness to economic performance - are worse. Today California has the highest poverty rate, highest unemployment rate and highest cost of living in America. We also have the highest tax rates. We pay the most and get the least: that is commonly known as a rip-off, and it is past time to end it. California does not need higher taxes. It needs a government that stops wasting the money it already takes. Which is too much. Operation Zero Waste will cut wasteful spending, shrink Sacramento bureaucracy and use the savings to help pay for Steve Hilton’s Califordable tax relief, including making the first $150,000 of income tax-free and establishing an 8% flat tax on income above $150,000. This is just the beginning of Operation Zero Waste, not a comprehensive list of every savings opportunity. We are starting with major areas where substantial savings have already been identified and will continue analyzing state government bloat to find more. Note: Some savings estimates overlap. CANCEL HIGH-SPEED RAIL: $3.78 BILLION California has spent years pouring money into High-Speed Rail while the project has fallen further behind schedule and grown more expensive. The High-Speed Rail Authority’s FY 2026-27 budget includes approximately $3.66 billion in capital spending and $117.9 million in administrative and capital support, totaling roughly $3.78 billion. A Hilton administration will end state support for High-Speed Rail on Day 1, based on State Controller candidate Herb Morgan’s analysis that these payments are illegal, given the enabling legislation for the payments which stipulates that High-Speed Rail should operate without subsidy. The most recent ‘Business Plan’ assumes ongoing public subsidy. 5% EFFICIENCY SAVINGS: $18.89 BILLION Every private sector organization is regularly asked to find efficiency savings. That has never happened in California state government. We are confident that efficiency savings can be found well in excess of 5%, however, for planning purposes we are assuming a modest 5% efficiency saving in the first year. That means reducing reliance on expensive outside contractors, consolidating duplicative legal and accounting services, cutting unnecessary administrative costs, reviewing jobs being performed outside California where there is no operational need, using AI and technology to modernize outdated systems, and eliminating spending that does not produce results. The $18.89 billion estimate shows the scale of savings available from applying just a 5% savings requirement across all state government departments. California taxpayers should expect the same basic cost discipline from state government that any well-run organization would demand. 10% BUREAUCRAT REDUCTION: $2.81 BILLION California’s executive branch has become too large and too expensive. The number of state bureaucrats has ballooned from 215,000 in Gavin Newsom’s first budget to over 250,000 in his final budget. California’s actual performance on every meaningful metric had declined over the same period - indeed nearly 2 million Californians, on net, have moved out of the state. A 10% reduction in executive-branch headcount is estimated to save approximately $2.81 billion based on current salary costs. This will be limited to bureaucracy and administrative bloat, not frontline public safety and essential services. This is one example of how the broader 5% efficiency target can be achieved, so the $2.81 billion should not simply be added on top of the $18.89 billion estimate. MEDI-CAL REFORMS: $11.49 BILLION California needs to bring Medi-Cal spending under control and focus resources on the people the program is intended to serve. Potential savings identified include: Ending state-funded full-scope Medi-Cal for undocumented immigrants: $8.5 billion Medi-Cal asset-limit reforms: $790 million Premium reforms for certain adults 19 and older: $1.1 billion Prospective Payment System rate reforms: $1.1 billion Together, these reforms represent approximately $11.49 billion in potential savings. DEFUND THE HOMELESS INDUSTRIAL COMPLEX California has spent billions on homelessness while the crisis has continued to get worse. Too much of that money is swallowed up by a Homeless Industrial Complex of developers, contractors, consultants and nonprofits that gets paid regardless of results. California is paying roughly $500,000 to $650,000 for a single unit of homeless or affordable housing, compared with approximately $150,000 to $350,000 in other states. In some parts of the state, for example the Bay Area and Los Angeles, there have been instances of per unit costs as high as $900,000 or even $1 million. Bringing California’s costs closer to the national average could save at least $1 billion while delivering the same amount of housing. A full costing will require full access to budgets and contracts. Operation Zero Waste will cap what taxpayers can be charged per unit, bring California’s construction costs back in line with the rest of the country, and stop rewarding politically connected developers and contractors for overpriced projects. Eventual savings could be far higher. ENDING THE NONPROFIT RIP-OFF California taxpayers should not be paying layers of nonprofits and middlemen to distribute government money, especially when taxpayer-funded organizations are engaging in political advocacy and voter mobilization. Examples include: Elevate Youth California: More than $370 million in cannabis-tax funding has been administered through Sierra Health Foundation’s Center, including grants to organizations that also engage in voter registration and mobilization. SOMAH, GRID Alternatives and CEJA: California has committed roughly $1 billion to the solar program. GRID Alternatives helps administer the program and CEJA handles community outreach, while CEJA’s affiliated political organization endorses candidates and mobilizes voters. Examples of financial intermediaries and unjustifiable fees include Community Partners (9% private grants, 15% government), Tides Foundation/Center (Model A full sponsorship or Model C for grantmaking-focused), Social Good Fund (5-10%), Charitable Ventures of Orange County (8-12%, 15% public contracts, $10k minimum fee), San Francisco Study Center, Earth Island Institute, and others such as Fulcrum Arts (7% plus annual fee). Operation Zero Waste will cut unnecessary nonprofit middlemen, demand transparency about where taxpayer dollars ultimately go, and require a clear separation between taxpayer-funded programs and political activity. END VANITY AND POLITICAL SPENDING Taxpayers should not be forced to pay for vanity projects or political activity. Operation Zero Waste will target spending on things like First Partner initiatives, taxpayer-funded governor portraits, and state money that supports political activity such as voter registration and ballot harvesting. CHIRLA: In 2024, CHIRLA received $25.6 million in government funding, approximately 82% of its total revenue, and received roughly $72 million in government funding over three years. Its affiliated Action Fund endorses candidates and conducts political organizing. Political activity by organizations like CHIRLA will be defunded. Government should spend taxpayer money on delivering services, not promoting politicians or political causes. THIS IS JUST THE BEGINNING These are the starting points for Operation Zero Waste. We will continue analyzing state government, department by department, program by program to identify additional savings, including: Overlapping agencies and bureaucracies Duplicative contracts and unnecessary administrative costs Programs that continue spending taxpayer money without producing results. RADICAL TRANSPARENCY Finding waste is only part of the job. Californians should also be able to see where their money is going and what they are getting for it. A Hilton administration will make state spending transparent so Californians can see where their money goes, who receives it and what results taxpayers are getting in return. Modern analytics and AI will help identify duplicative contracts, excessive administrative costs, unusual or fraudulent spending and programs that continue receiving taxpayer money without delivering results. That makes Operation Zero Waste an ongoing process, not a one-time round of savings. We will keep finding waste, make sure promised savings actually happen and hold Sacramento accountable for how taxpayer money is spent, working with State Controller Herb Morgan and his Radical Transparency initiative. Better services. Less bureaucracy. Lower taxes. ← Back to all policies

---
snapshot_id: 0889f9c3-2f6c-5722-b693-52558bd8202d
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor's Debate (Nexstar) - OTR page: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e - Video: https://www.youtube.com/watch?v=qRNZ0kuA49k - Date on On the Record: 2026-04-23 - Kind: debate · Governor's Debate (Nexstar) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:15] Everyone can see things have gone off track. Life is impossible. [8:50] We have to make these changes because Californians are being crushed by the gas prices, by the gas tax. We have the highest gas tax in the country for the worst roads in the country. And across the board, we have the highest taxes for the worst results. And you know who's really suffering? It's working Californians. It's small businesses. Most of my career has been in business. I know what it's like to try and run a business. The costs that are being imposed on our businesses and our workers in California is just too much. And one way or another, all the Democrats here are part of this system that obviously isn't working. We need common sense solutions. We need practical solutions. Why are we importing oil from 7 ,500 miles away in Iraq rather than using the oil we have here in California? That's the kind of common sense change that as governor, I will be there to persuade the legislature to do. Because they, in the end, want to help Californians too. [10:05] The first point is that to open up California oil production doesn't need the legislature because it's through executive action. The way that they've been closing it down is through an agency of the executive branch called CalGEM, the California Department of Geologic and Energy Management. I would replace the people in there and give them a clear instruction to issue permits to our oil industry to produce oil here in California so we can cut gas prices for California families and businesses. [14:14] No, we cannot keep going in this direction with Democrats constantly going for their insatiable appetite for more and more taxes for their bottomless money pit, and now the mileage tax, they want to track you everywhere you drive. No, I would veto that. We need to cut spending and cut taxes so that we can give relief to families and businesses. My plan is for $3 gas and your first 100 grand tax free. That's what we need to do to make our state Cal affordable. [22:01] Well, by the way, I'd love to be in your class, Katie. If you get a B for what Gavin Newsom's done on homelessness, my goodness, of course it's an F. It shames our state, the situation with homelessness. We have about 10 % of the US population, around 50 % of the country's homeless population. And as for Javier praising Gavin Newsom for the photo op where he tried to pretend he was cleaning up a homeless encampment, literally, Gavin Newsom did that three times in a row. Nothing changed, and nothing will change if you have one of these Democrats in power. It will be more of the same. My plan is a common sense three -point plan. Number one, it is illegal to live and camp on the streets. We need to enforce the law. Number two, we need to get people into the drug treatment that they need, and it cannot be a choice. Number three, we need to get people the mental health care that they need instead of the barbaric situation we have right now in California as a result of these Democrat policies where the main place where we're treating people with mental health problems is jail. That has to change. [23:14] everything has taken us in the wrong direction. That's why we spend, what is it? The state auditor found $24 billion of our money spent on homelessness. They have no idea where it went because it's going into these nonprofits and crony developers that are, instead of solving the problem, they are profiting of these Democrat policies. Okay, Mr. Hilton, thank you. Your time is up, [33:17] One of the proudest days of my life was the day I became an American citizen. It happened in a ceremony right here in San Francisco. So it is a deep honor for me to be endorsed by the President of the United States and here's the thing that's gonna help every Californian when I'm governor is that we will have a constructive relationship and partnership with the federal government which would be the case, I would hope, for any party in that situation so that we can make things better in California, work with the president and his administration to manage our forests better, to harvest the timber so we can build the single -family homes we need for young families, to work to increase California energy production as he wants to do so we can lower gas prices, to fight the fraud in our government so we can cut spending and cut taxes, to work to enforce our immigration laws in all these areas and more. It will benefit every Californian to have a governor who is a partner on these issues with the president and his team. [36:17] that again, Tom. Wait, no, no. Mr. Hilton. [36:24] putting more money into the system. [42:39] So I've discussed this with someone called Marcus Coleman from Bakersfield. His beautiful daughter, Delilah, was put into a coma by someone driving a truck, an illegal immigrant, didn't speak English, and his daughter now disabled for life. That's what we're dealing with here. It is completely ridiculous that we have people driving on our roads who can't understand road signs and can't speak English. So yes, of course, and I've discussed this with my friend, Sean Duffy, the transportation secretary. We will not be issuing commercial driver licenses when I'm governor to people who are illegally here and who don't speak English. That is obvious common sense. [50:46] I will because we've had 16 years of one party rule by these Democrats. It's given us the highest poverty rate, the highest unemployment rate, the highest cost of living in America. It is obviously desperately time for change in California. It's time for some balance in our system. We have to elect a Republican as governor this year. [54:31] We obviously need change in California. The system is not working. I'm the only one here who has never run for office before. I'm not part of this system. These Democrats can't get it done. Matt Mahan talks about his record in San Jose. Actually, homelessness and crime are going up. Javier Becerra talks about his time in government. He thought it was a good idea to put masks on two -year -olds. We need real change in California. We need to think different. We need to vote different. My plan to make our state Cal -affordable is real and serious, and we can get it done if we just vote differently this year. [59:33] Well, if San Jose is the template for housing affordability in California, God help us, it was just rated the least affordable city for housing in the world. That is completely the wrong answer. The right answer is my plan, which was the first plan that I put forward in this campaign. Number one, we have to end this outrageous hidden tax on housing. They call it impact fees. It can add up to 20 % to the cost of a home. Secondly, we have to reduce the extreme environmental regulations that make it three or four times as expensive to build the exact same home in California as in neighboring states. Number three, we have to end the exploitative union lawsuits that are filed to block housing that extract project labor agreements that make the cost so much higher. And number four, we have to end the war on single -family homes so that we can build the housing we need for young families. We need more starter homes in California. [65:54] It's an absolute scandal that we have just under half of our students can read at grade level for math. It's 35%. Here's the plan. We're gonna learn from what works in other states and around the world. The best way to teach kids to read, phonics. We're gonna have that in every school. The most important thing is that you learn to read by the end of third grade. Just as Mississippi has done, we're gonna make sure, we're gonna give you help over the summer if you can't but if you don't meet the test, you repeat the grade and then you can move forward and we're gonna hold teachers and schools accountable for their performance. [70:09] We have to be clear about why they left. They left because of Democrat policies and wrong -headed regulation. Now, some of those mistakes have been corrected. The ability for insurance companies to price in future risk, the ability of insurance companies to account for reinsurance costs, but we still have wrong regulation and this is the three -point plan that I've announced to fix this absolutely massive problem that is crushing so many families across California. Number one, we've got to get people off the fair plan. It was designed for about 100 ,000 people. Now you've got over 600 ,000. We've got to work proactively to get those people onto commercial insurance. Number two, we have to stick to the regulatory framework that was in the original proposition that set up the insurance department. 60 days to make to approve rate changes. Sometimes now it's over a year. And number three, we have to stop these nuisance lawsuits often filed by private equity from out of state that are increasing the cost of insurance. All right, [75:53] So as the father of two teenage children, I know this issue very well. But actually it's an issue that I've been thinking about and advocating on for many, many years. 11 years ago, in my book, More Human, 2015, that was published, I made the argument that it's not just the apps, it's not just the platforms, it's the screens themselves and that we should set a social norm that children under 16 should not have a smartphone. That is my position now. I think that every parent in their heart knows that it's wrong. Kids do not need smartphones and we shouldn't allow it. [76:38] I think it misses the point, honestly. I think that we've got to get to the heart of the problem and that's the devices and the screens. [82:14] In the middle of it right now is Reacher. One of my sons really enjoys that. Probably more than the rest of us in the family but it's been good fun to watch together.

---
snapshot_id: d8796707-54e8-5acb-9eee-a45d04cd9efb
source_kind: pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)
url: https://www.ontheissues.org/Steve_Hilton.htm

Steve Hilton on the Issues Follow @ontheissuesorg On the issues: Steve Hilton Hilton's Profile Governor Match | Other CA Candidates: Antonio Villaraigosa Eleni Kounalakis Eric Swalwell Gavin Newsom Katie Porter Tom Steyer Xavier Becerra Zoltan Istvan CA Governor (Republican challenger) Steve Hilton On the issues>> Wikipedia Ballotpedia Contact Steve Hilton Take the Quiz! VoteMatch CA politicians Governors (2026 election unless otherwise noted; AK : Mike Dunleavy (R,term-limited) vs. Click Bishop (R) vs. Nancy Dahlstrom (R) vs. Tom Begich (D) vs. Jonathan Kreiss-Tomkins (D) vs. Bernadette Wilson (R) vs. Bill Walker (I) AL : Kay Ivey (R,term-limited) vs. Doug Jones (D) vs. Tommy Tuberville (R) vs. Will Boyd (D) vs. Yolanda Flowers (D) AR : Sarah Huckabee Sanders (R,for re-election) vs. Fredrick Love (D) AZ : Katie Hobbs (D,for re-election) vs. Andy Biggs (R) vs. David Schweikert (R) vs. Karrin Taylor Robson (R,withdrew) CA : Gavin Newsom (D,term-limited) vs. Xavier Becerra (D) vs. …

---
snapshot_id: c5cb2800-c981-5e7d-b5c4-76e2f72d1698
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000

Saved from https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000 (rendered page text, built-in browser, 2026-10-07) POLICY NO STATE INCOME TAX ON YOUR FIRST $150,000 ← POLICY ARCHIVE NO STATE INCOME TAX ON YOUR FIRST $150,000 THE PROBLEM California families are getting squeezed from every direction. Housing costs are out of control. Utility bills keep rising. Groceries cost more. Insurance costs more. Child care, gas, and health insurance continue to get more expensive. For too many Californians, it feels harder every year to get ahead. At the same time, the political establishment keeps asking Californians to pay more while delivering less. The quickest, simplest, and most direct way to put more money in people’s pockets is for the government to take less out. Yet today, California’s government is gouging working families and small businesses with some of the highest taxes in America. California has the highest income tax rate in the nation. The highest statewide sales tax rate. The highest gas tax. Over the last decade, state spending has roughly doubled. Yet the results have gotten worse. California now ranks 50th out of 50 states for opportunity in U.S. News & World Report’s Best States rankings. California has the highest poverty rate in America when cost of living is taken into account. California has one of the highest unemployment rates in the nation. California’s highway system ranks 49th out of 50 states overall, and 50th out of 50 for urban arterial pavement condition. Californians are paying more than ever, yet getting less in return. California’s 9.3% income tax bracket begins at roughly $72,000 of taxable income for married couples. That rate is higher than the top income tax rate in most states. THE HILTON PLAN Under Steve Hilton’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. Millions of Californians would see an immediate tax cut and keep more of their own money for housing, childcare, groceries, retirement savings, or whatever matters most to their families. The result is a tax system that is lower, simpler, and fairer for California families. WHAT IT MEANS FOR YOU For a married couple filing jointly using the standard deduction and assuming an 8% tax rate on income above $150,000: A family earning $150,000 would pay no California state income tax. A family earning $200,000 would save more than $7,000 every year. CAN CALIFORNIA AFFORD IT? Whenever Californians ask for tax relief, the political establishment says there’s no money. Yet California is projected to collect more than $226 billion in General Fund revenue this year. Independent estimates suggest eliminating state income tax on the first $150,000 of income and applying an 8% rate above that threshold would reduce revenues by approximately $40 billion annually. That represents roughly a 17.6% reduction in projected General Fund revenues. The elimination of state income tax on the first $150,000 of income accounts for approximately $20.9 billion of that total, or about 9.2% of projected General Fund revenues. Even after this tax cut, California would still collect roughly $187 billion in General Fund revenue every year. That is about the same amount the state collected in 2020-21. At the start of that period, California had roughly 200,000 more residents than it does today. If California could serve a larger population with roughly the same revenue then, it can do so again today. Californians are not undertaxed. State spending roughly doubled. Housing costs soared. Utility bills rose. Insurance premiums climbed. California became less affordable. And when the political establishment claims there is no room for tax relief, Californians have every reason to be skeptical. During the pandemic, California’s Employment Development Department lost an estimated $50 billion to $55 billion in fraud and improper payments. The State Auditor found that EDD did not take substantive action to strengthen fraud detection until months into the pandemic, paid billions in claims it could not verify, and even paid an estimated $810 million in fraudulent claims filed under the names of incarcerated individuals. California spent nearly $24 billion on homelessness programs over five years. The State Auditor found that state officials could not consistently measure whether the spending actually reduced homelessness. Before asking Californians to pay more, government should prove it can responsibly manage the money it already receives. Californians deserve tax relief. State government should learn to live within a budget that was sufficient just a few years ago. THE BOTTOM LINE Under Steve’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. For millions of families, that means thousands of dollars every year staying in their household budget instead of going to the government. California’s affordability crisis won’t be solved by asking families to pay more. It will be solved by letting them keep more of what they earn. ← Back to all policies

---
snapshot_id: 183796f6-60c2-5b02-850a-d1fb3a8700c2
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/77f91eb0-90c0-47d7-8c37-cda599ea643b

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (NBCLA and Telemundo) - OTR page: https://ontherecord.empowered.vote/meetings/77f91eb0-90c0-47d7-8c37-cda599ea643b - Video: https://www.youtube.com/watch?v=UUOsiG5tkDU - Date on On the Record: 2026-05-07 - Kind: debate · Governor Debate (NBCLA and Telemundo) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [2:32] Yes, the California dream was built on that idea of owning your own home. And right now we have the highest housing costs in the country and the lowest home ownership. Young people saying to me all the time, I can't imagine making my life in California because I'll never be able to own my own home. We've got to change direction on housing. Yes, we've got to simplify the regulations that make it so expensive, two or three times more expensive to build housing compared to other states. Yes, we have to stop the hidden taxes on house building. But the big change we need to make, which the Democrats on this stage aren't prepared to make, is to end this ideology which says the only acceptable form of housing is to shove apartment buildings into suburban neighborhoods. We've stopped building the kind of starter homes and single family homes we used to build so well in California that made the California dream a reality. And that is what I will get back to as governor to restore that California dream of home ownership. [9:16] He's trying to remember his lines. [12:31] Exactly. [15:19] So just a couple of observations on what we heard in the previous answers. I love all the stories of the California dream for some of my friends and colleagues on this stage, but the California dream they're talking about happened when you had a Republican governor in California. And that's what we need to get back to to restore it. Matt Mahan talked about housing. His city was just rated the least affordable for housing in the world. So what that all points to is that actually if we want change in California on all these issues, we can't keep doing the same thing over and over again, specifically on insurance. The things we haven't heard that I would do as governor is number one, enforce the actual regulation in the original proposition 103 that set up our insurance commission and the regulations around it, which says that rate changes need to be approved in 60 days. Now it takes over a year. That's one of the reasons that they're leaving. And the other massive one, lawsuits. Lawsuits are adding sometimes up to $15 ,000 a year on to run to insurance premiums. And these Democrats won't change it because they are funded by the trial lawyers. [20:21] We are going [21:24] No. [21:25] Stop spending tax -based money on pointless things and improve our roads, which are the worst in the country because of [21:32] policies. [21:50] either yes or no. The bill's [24:49] So Matt mentioned restaurants. I actually did open a couple of restaurants, but not here, back in the day in England, before we moved here with my wife and my family in 2012. And unbelievably, it's actually much harder to do it here in California, which should be the home of enterprise and opportunity, the best place in the world to do business. And the fact is, when we talk about all those issues, there's this famous saying that comes to mind. The definition of insanity is doing the same thing over and over again and expecting a different result. Well, here in California, we've been voting Democrat over and over and over and over again. And look at the results. The highest unemployment rate in the country, the highest poverty rates, the worst climate for business. We cannot expect to make changes for the better if we keep voting Democrat. I will exclude Antonio. I agree with you, Antonio. You definitely have a more pragmatic approach to this, and that's what we need from our next governor. Thank you, Mr. Hilton. A problem -solving, pragmatic, common sense approach. [26:05] 50th out of 50 states by Chief Executive Magazine. And the person on [30:39] of Democrat one -party rule, why do you think that [31:57] No. [32:04] Are you happy with that, Tom? How do you want to be charged by Matt? [39:38] I was just trying to offer a fact check. Homelessness actually has gone up in San Jose. It's actually [39:55] you noted, he didn't challenge the fact that homelessness has gone up on his watch. Now, [40:02] the good news in this debate is that actually there's a lot of agreement among many of the candidates about the nature of the problem and how we solve it. But we've got to think about the fact that who's been in charge [40:15] all these years? Some of these Democrats on the stage, they talk as if we're in some parallel universe where Democrats haven't been running this state for the last 16 years of one -party rule. You look at Javier. 36 years he's been a career politician for Democrats. It's just got to change. We need change if we're going to make progress. And that is what Chad's plan is exactly right. And I just add one thing to it, which is we need to enforce the law when it comes to homelessness. Just as Spencer Pratt laid out in the mayor's debate to you earlier, it's illegal to live and camp on the streets. And that's the starting point. A [42:10] I haven't done. [42:15] ask [42:17] I didn't. [43:34] Thank you very much. I tell you what I haven't done, Javier, is break state and federal law by taking money from a campaign account and funneling it to a senior aid, breaking those laws and then denying it. I tell you what I haven't done, which we reveal today, which is to take a taxpayer -funded organization from your money, your taxes, are paying illegal immigrants to campaign for Javier Becerra through an organization called CHERLA. And he's accepted their endorsement. It is completely outrageous. [52:43] Thank you very much. Unlike everybody else here, I actually am an immigrant. I'm a proud American, American citizen. And I am the candidate of the legal immigrant community for the legal immigrant community so that they can have the California dream. Just as my parents had it when they moved from Hungary, fleeing communism to build a new life in England. That's what California is all about. But it's got to be managed and orderly and legal. And that's what we have to be honest about in this whole discussion about immigration and its enforcement. I can tell you very clearly that when I'm governor, as I've said, I will be there for our immigrant communities, our legal immigrant communities, but also we'll make sure that all our laws, all our laws, are peacefully enforced. We can't just stand up here and decide which laws we like and which laws we don't. If we don't like the laws, we've got to change them. But the governor's job is to enforce them. And as governor, I will do that peacefully and calmly and cooperatively with the federal immigration authority. [53:57] I understand exactly what it's like to be in a country without those privileges because that's my life and my story when my parents fed communism in Hungary and I grew up in a household with a single mother, working -class immigrant story, just like so many millions in California. My stepdad worked construction. My first job, project manager for a construction company. So, yes, I absolutely understand that. And that opportunity is what I want for every single one of you. Thank you, sir. Every single one. [55:28] Yeah [55:32] It's a weird question, to be honest. I agree with Katie. [55:40] I think you might even [56:03] it open. [56:10] Extend [56:13] Yes, extend it and build new ones. [56:17] Completely nuclear. [56:30] Yes. [56:31] Yes. [56:33] Yes. Yes, I published my plan on this last week. I would exceed other countries. We got to be the best in the world.

---
snapshot_id: ea1977b8-1699-59ca-b7e7-1a1dd02a9e21
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/fd5e0064-917c-4522-9ed4-e3fa71f289c1

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Candidates on Homelessness (CBS News) - OTR page: https://ontherecord.empowered.vote/meetings/fd5e0064-917c-4522-9ed4-e3fa71f289c1 - Video: https://www.youtube.com/watch?v=EHkU_NAZJZ4 - Date on On the Record: 2026-04-12 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [0:15] homeless population? Enforce the law, get people into treatment, and increase mental health capacity by getting a waiver from the Medicaid IMD rule that stops any um institution with more than 16 beds getting Medicaid funding. Enforce the law, get people off the streets into treatment, whether that's drug treatment, um mental health treatment, job training. We got to get we Look, here's a simple way of putting it. We wouldn't accept someone we loved living in those conditions on the street. [0:45] >> You require the treatment. And and that's why [0:48] >> it's it's it's actually illegal under California law because in 2016, a bill was passed which has become known as Housing First. That's the name of the policy. It was actually originated in the Obama administration as federal policy implemented through HUD, Housing and Urban Development. California was the only state to actually turn that into state law, which makes it illegal for any organization receiving state money for homelessness to require any kind of response from the from the client, whether that's treatment or or anything. So, what you have is this crazy situation. I've been there. So, [1:28] >> What do you [1:31] Well, again, my first step, invite the legislature to overturn this law. Um if they won't do it, then we have to step in at the state level through executive action to to Just as Gavin Newsom is doing right now. I mean, he's he's sent just just on the day that we're um recording this conversation, he made an announcement that he's What's he going to do? He's going to have crime suppression teams sending in uh from with state resources, state law enforcement going in um to cities and he's going to clean homeless homeless The the latest promise is clearing homeless encampments in 30 days. And so, he's using the power of the state to forcibly act where cities and counties haven't done their job. And if he can do it, then so can I. And I will. And let's hope, by the way, that he has dealt with the problem. I hope he does work. I hope it does work this time and isn't just the latest example of of words from Gavin Newsom that aren't matched by

---
snapshot_id: 7f16187c-5cd3-5d10-be38-62e05bab41b8
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/hilton-surges-ahead-in-governors-race-emerson-poll/

Hilton Surges Ahead in Governor's Race: Emerson Poll - Steve Hilton for Governor Skip to content ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate Hilton Surges Ahead in Governor’s Race: Emerson Poll Share This April 7, 2026 9:21 am Steve Hilton the Frontrunner in the California Governor’s Race Statement from Steve Hilton: “The latest Emerson poll confirms what we’re seeing on the ground at our Town Halls up and down the state, with thousands of people just in the last month or so coming out to ask questions and join our movement for change. It’s the same reaction you saw in the first TV debate: when people see the clear contrast between 16 years of Democrat one party rule that have given us the highest poverty, highest unemployment and highest cost of living in America – and Steve Hilton’s positive, practical ‘Califordable’ plan: $3.00 gas, cutting electric bills in half, your first $100 grand tax free, a home you can afford to buy, Steve’s message wins hands down. “Californians can see that it’s time for an outsider to shake up a system that obviously isn’t working. We’re building the only Republican campaign that can unite the party, bring in independents, and beat the Democrat machine in November. “But there is a real danger that other Republican campaigns act as a spoiler, splitting the vote to allow two Democrats into the top two. That would be a total disaster, ending our chance for change in California. So now is the time for other Republicans to unite behind the Golden Ticket: Steve Hilton and his running mates Gloria Romero for Lieutenant Governor, Michael Gates for Attorney General, and Herb Morgan for State Controller. This is the strong, united team that will work to fight fraud and corruption through CAL DOGE, deal forcefully with crime, homelessness, and educational failure, and above all make our state Califordable.” Emerson College Poll: https://emersoncollegepolling.com/california-2026-poll-hilton-swalwell-bianco-lead-nonpartisan-primary-for-governor/ Share This Steve Hilton For Governor X-twitter Instagram Facebook Youtube Paid for by Steve Hilton for Governor 2026 By entering your phone number and selecting to opt in, you consent to receive SMS/MMS marketing and polling text messages, donation requests, updates, and other important information to that number from Steve Hilton for Governor. Msg&data rates may apply. Msg frequency varies. Reply HELP for help or STOP to opt-out at any time. SMS information is not rented, sold, or shared. View Privacy Policy and Terms & Conditions. To make a donation by check, please send your contribution to: P.O. Box 730 Hilmar, CA 95324 Press Inquiries ONLY: [email protected] Copyright &copy; 2026. Steve Hilton for Governor. All Rights Reserved Campaign News Contact Privacy Policy

---
snapshot_id: 07895308-8496-540a-b366-a9d31fa701f6
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/end-the-paga-trial-lawyer-extortion-racket

Saved from https://stevehiltonforgovernor.com/policies/end-the-paga-trial-lawyer-extortion-racket (rendered page text, built-in browser, 2026-10-07) POLICY END THE TRIAL LAWYER BUSINESS EXTORTION RACKET (PAGA) ← POLICY ARCHIVE END THE TRIAL LAWYER BUSINESS EXTORTION RACKET (PAGA) Trial lawyers have turned California’s little-known Private Attorney General Act (PAGA) into a corrupt, state-sponsored extortion machine under the guise of ‘enforcing state labor law.’ They file thousands of abusive lawsuits a year, often over minor technicalities. Small, family-owned and run businesses get hit hardest and settle just to stay afloat. This isn’t about protecting workers. It’s about enriching lawyers and imposing a hidden ‘stealth tax’ on business. Steve Hilton’s plan to end the PAGA business extortion racket puts labor enforcement back in the hands of the state’s labor agency, cutting out trial lawyers who profit from abusive lawsuits. The state would review claims, investigate credible cases, and issue citations with common sense remedies to ensure fair and impartial enforcement without turning labor law into a cash grab. BACKGROUND PAGA, the Private Attorney General Act, was passed in 2004. It outsourced the enforcement of California labor law to private trial lawyers, incentivizing them to harass businesses and extort money from them. Worse still, the government makes money too by taking the largest share of awards against employers, or settlements, after the lawyers take their payment. PAGA allows trial lawyers to sue any business for the most footling technical oversight, such as an incorrect date format on a pay stub. These lawyers have turned PAGA into a jackpot, with average settlements exceeding $1 million and over a third of that money going straight to attorneys. We now have the obscene spectacle of trial lawyers fishing for business on Instagram, parking trucks outside workplaces, wandering around business premises handing out cards to workers and encouraging them to terrorize their employer. Small businesses, often without in-house counsel, are especially vulnerable. PAGA is legalized extortion, and small businesses, especially those without big legal teams, are easy targets. Many settle just to avoid going under. For small businesses, multiple settlements per year in the high tens of thousands are routine, adding an enormous financial burden to already hard-pressed business owners, as well as anxiety, stress and time wasted on legal bureaucracy and paperwork. PAGA was originally passed because the California Labor Commissioner was understaffed and claimed to be unable to investigate labor complaints adequately. But that was two decades ago. Today, with modern case management systems and tools like artificial intelligence, the Labor Commissioner’s office could efficiently review and manage complaints even with limited staff. It’s time to take enforcement power back from trial lawyers and return it to neutral state officials equipped to handle it responsibly. STEVE HILTON’S PLAN: END THE SHAKEDOWNS & RESTORE FAIRNESS As governor, Steve Hilton will overhaul California’s broken PAGA system and return enforcement to where it belongs — with the Labor Commissioner, not trial lawyers looking to cash in. His plan includes: Appointing pro-reform leadership at the Labor and Workforce Development Agency. A new Secretary of Labor and State Labor Commissioner, committed to fairness, compliance, and timely resolution, will restore trust and functionality to California’s labor oversight. Executive action to reform PAGA enforcement. Hilton will direct the Labor Commissioner’s office to fully assert its authority to review and investigate claims using existing staff and resources. This will ensure the state, not profit-driven lawyers, decides which violations warrant action and how to resolve them. Make enforcement smarter and more efficient. Modern tools like artificial intelligence and improved case management systems will help the Labor Commissioner’s office identify abusive claims, prioritize credible cases, and accelerate investigations. These upgrades will lead to faster, fairer outcomes for both workers and employers. Legislation to modernize PAGA. Hilton will work with lawmakers to replace the current lawsuit-first system with an administrative model that puts investigations and resolution in the hands of neutral public officials. Credible claims will result in citations and remedies instead of jackpot lawsuits. PAGA was meant to ensure fair labor standards, not enrich attorneys. Under Steve Hilton’s leadership, California will take enforcement back from the trial lawyer lobby and build a system that protects workers, respects employers, and strengthens our economy. ← Back to all policies