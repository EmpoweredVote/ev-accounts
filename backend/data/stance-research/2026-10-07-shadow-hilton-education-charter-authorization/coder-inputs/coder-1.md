You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-education-charter-authorization/labels/coder-1.json. Write JSON only, matching
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


## Sources

---
snapshot_id: 9998bc56-1272-5d67-9d10-e68d5a131d44
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again

Saved from https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE ← POLICY ARCHIVE MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE THE PROBLEM California’s public schools are failing millions of students. Only 47% of students meet English language standards, and just 35% meet math standards, compared to the roughly 60% of students nationwide that meet their state’s English standards and 65% that meet state math standards. For Black and Latino students, the numbers are even worse. Nearly 70% of Black students and 64% of Latino students do not meet basic standards in reading. These failures are concentrated in the early grades, where students are falling behind and never catching up. Research shows that if a child cannot read proficiently by the end of 3rd grade, they are four times more likely to drop out of high school. That is why fixing early education and ensuring literacy by 3rd grade must be the cornerstone of any serious education reform. HOW WE GOT HERE California spends more than $22,000 per student each year, among the highest in the nation, yet outcomes continue to decline. This is not a funding problem. It is a leadership and accountability problem. Politicians backed by teachers unions have removed phonics-based reading instruction, abandoned Algebra in middle school, stripped away consequences for failure, and added ideological curricula that crowd out basic skills. At the same time, the state has made it nearly impossible to reward good teachers or remove ineffective ones. Schools are no longer judged by whether students learn, but by whether bureaucratic boxes are checked. In too many places, especially low-income communities, the system seems designed to protect itself rather than serve children. STEVE HILTON’S SOLUTION: 3RD GRADE FIRST As governor, Steve Hilton will make 3rd grade literacy and numeracy a top education priority. His plan includes structural change, immediate classroom reforms, and full accountability to parents. This approach does not require more spending. It requires a new focus on results. 1. RESTORE PHONICS-BASED READING INSTRUCTION IN ALL K–3 CLASSROOMS. Phonics is the most proven method to teach children to read, but California does not require it. Steve Hilton will use executive action and pro-reform appointments to the state Board of Education to mandate phonics instruction statewide. 2. HOLD SCHOOLS ACCOUNTABLE FOR 3RD GRADE READING RESULTS. Every school will receive a clear, public letter grade each year based on student proficiency, starting in 3rd grade. Schools that fail to show improvement will be placed in state-directed “special measures” with new leadership, strategies and greater accountability. 3. REFORM TENURE, TEACHER EVALUATIONS, AND DISMISSAL POLICIES. With Steve Hilton as governor, California will require at least five years of classroom experience before granting tenure. Low-performing teachers must be removed quickly and excellent teachers rewarded. 4. BRING BACK AND EXPAND THE PARENT TRIGGER LAW. Parents will once again be empowered to force reforms at failing schools. If a school receives a D grade two years in a row, parents will have the right to trigger administrative changes, curriculum overhauls, or conversion to a charter model. 5. LAUNCH EDUCATION SAVINGS ACCOUNTS AND CROSS-DISTRICT OPEN ENROLLMENT. To give parents immediate options while traditional schools improve, Hilton will expand choice through ESAs, starting with low-income and special needs students. Parents will be free to move their children to any public school that performs better, regardless of zip code. Steve Hilton believes California can lead the nation in education again. But it starts with getting every child reading properly by 3rd grade. ← Back to all policies

---
snapshot_id: a5ff5d1e-bb63-5895-a2c5-1f33aae2d0c0
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: 62d63076-4e43-5c4e-a4dc-0e17a8b022f2
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/save-small-business-street-vending

Saved from https://stevehiltonforgovernor.com/policies/save-small-business-street-vending (rendered page text, built-in browser, 2026-10-07) POLICY A CALIFORDABLE PLAN TO RESTORE LOCAL CONTROL OVER STREET VENDING ← POLICY ARCHIVE A CALIFORDABLE PLAN TO RESTORE LOCAL CONTROL OVER STREET VENDING Stop the street vendor war on small business and abolish the state sales tax on restaurant meals. California's small businesses are being punished for doing the right thing. Restaurants and local retailers pay rent, wages, taxes, insurance, utility bills and permit fees. They pass inspections and follow health and safety rules. But a street vendor selling the same products can set up nearby without those costs. If the vendor is operating illegally, the consequence may be little more than an administrative fine. Once again, Sacramento rewards people who break the rules and punishes people who follow them. Even worse, the people following the rules are paying for a government that refuses to enforce them. There must be a statewide ban on street vendors that directly compete with brick and mortar businesses. Enough is enough: it is time for the government to be on the side of the hard-working, law-abiding majority. It is time to save small business in California. THE PROBLEM In 2018, Sacramento passed SB 946 and took street-vending policy away from local communities. The law applies to charter cities as well as general-law cities. It prevents cities from limiting the number or location of vendors unless they can prove an objective health, safety or welfare concern. It specifically says that harm to existing brick and mortar businesses does not count. Even repeat violations are generally subject only to capped administrative fines. SB 972 later downgraded violations of food-safety laws by sidewalk vendors and compact mobile food operations to administrative offenses. Cities are left to deal with the consequences, but Sacramento will not let them use the tools needed to solve the problem. Restaurants are already fighting to survive. The Los Angeles Times counted more than 100 notable restaurant closures in Los Angeles in 2024 and more than 100 again in 2025. Federal figures show that California restaurants and other eating places lost more than 28,000 jobs across those two years. Street vending is one of many pressures on restaurants. Sacramento has made a brutal business environment worse by protecting direct competitors that do not carry the same costs. BECERRA CHOSE STREET VENDORS OVER SMALL BUSINESS Xavier Becerra has made his choice. Speaking to NALEO, he said that you do not get “real street tacos” from a long-standing restaurant, but from the guy who makes them in his little cart. That restaurant pays rent, wages, taxes, insurance and permit fees. Becerra told its customers to go somewhere else. He chose street vendors over the legal restaurants that create jobs and follow the rules. Steve Hilton, who as a small business owner started and ran restaurants himself, will stand with small business. THE PLAN 1. BAN UNFAIR COMPETITION WITH BRICK AND MORTAR BUSINESSES Steve Hilton will send the Legislature a bill banning street vendors from directly competing with brick and mortar businesses. The law will establish a protected buffer around restaurants and retailers when a vendor sells substantially similar food or merchandise. Cities will be free to create larger protected areas or prohibit street vending altogether. Street vending may continue outside those protected areas where local rules allow it. The statewide rule is simple: street vendors will no longer be allowed to set up next to an existing business and steal its customers while avoiding the costs that real small businesses are required to pay. 2. REPEAL SACRAMENTO'S RESTRICTIONS AND RESTORE LOCAL CONTROL The same bill will repeal Chapter 6.2 of the Government Code, created by SB 946, and the related restrictions on local enforcement. Cities will once again be able to regulate the number, location and operating hours of vendors and consider the harm done to existing businesses. Cities will be able to require permits, revoke them, impose meaningful penalties and impound equipment when someone repeatedly violates the law or continues operating without the required permits. 3. ENFORCE EXISTING LAWS NOW While the bill moves forward, Steve will direct state agencies to enforce existing tax, food-safety, labor and business laws. His administration will also support charter cities that challenge Sacramento's restrictions in court on the grounds that managing local streets and sidewalks is a municipal responsibility. 4. TAKE IT TO THE VOTERS IF NECESSARY If the Legislature refuses to act, Steve will lead a statewide ballot initiative to Save Small Business in California, impose the ban on unfair competition, repeal Sacramento's restrictions and restore local enforcement power. The Sacramento politicians created this mess. If they refuse to fix it, California voters will. 5. ABOLISH THE STATE SALES TAX ON RESTAURANT MEALS Steve will abolish the state sales tax on restaurant meals. That means removing the 3.9375 percentage points that currently go to the state General Fund while leaving local sales taxes and dedicated local revenue in place. Californians will save nearly $4 on every $100 they spend at restaurants. Federal household spending data indicate that the average Western household spends $4,708 a year on food away from home. At that level, Steve's tax cut would save the average household about $185 a year, or $15 a month. The California Department of Tax and Fee Administration reported $105.8 billion in taxable transactions at full-service and limited-service eating places in 2025. Based on those sales, abolishing the state General Fund portion of the tax will cost approximately $4.2 billion a year. We will account for that cost as part of Steve's broader Califordable agenda. Operation Zero Waste will cut spending elsewhere across state government to offset this and other Califordable tax relief. We will not raise another tax to pay for it. A BETTER WAY FORWARD California should be on the side of people who work hard, create jobs and follow the law. Today, those people pay the bills while Sacramento protects competitors who avoid them. Same old story under Democrat rule: the people who do the right thing are punished, those who do the wrong thing are rewarded. We will end the street vendor war on small business, abolish the state sales tax on restaurant meals and put government back on the side of hard-working, law-abiding Californians, to help save small business and lower costs for Californians. ← Back to all policies