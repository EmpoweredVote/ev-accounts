You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-misinformation/labels/coder-3.json. Write JSON only, matching
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

politician_id: 0f74219c-7d10-4d29-85fe-0f1d834df8a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Xavier Becerra — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: misinformation
topic_id: ddd65d64-9dc7-4208-a30f-59f4b9c0653d  served_revision_id: bd313c07-02a5-4344-8cc3-0e4b4c3b78a1
Question: What responsibility do platforms and government have in combating online misinformation?
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


## Sources

---
snapshot_id: 7a2c5fb9-10bc-5e8c-a167-0ee6d8b0c187
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## debate — California Governor's Debate (Nexstar) - OTR page: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e - Video: https://www.youtube.com/watch?v=qRNZ0kuA49k - Date on On the Record: 2026-04-23 - Kind: debate · Governor's Debate (Nexstar) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:36] Listen, I've been confident I can get those voters since the day I jumped in about a year ago. [6:00] Frank, we need to make sure our roads, our highways, the potholes, we take care of business because every day people get in their cars, they take transit, they need to get to work, they need to come home. The last thing they need to see is infrastructure for roads and transportation that doesn't work. I remember when my parents would tell me the stories of when they came with $12 in their pocket. They had to make a life here. They needed to make sure California could work for them. Let's make sure Donald Trump is not starting reckless wars to keep the prices of gasoline down. By up to $2 a gallon, we could reduce the price of that war in Iraq that Donald Trump started would go away. My parents looked at things like this and said, hey, help me make a living here in California. That's why they were able to, at the end of the day, send my three sisters and I to college, buy a house, make it so that they could retire here in California. We need to bring down those prices, but we have to do it the right way. I'll make sure, as governor, I tackle these crisis because I've been through these crisis before and had to handle them. We need someone with experience, someone who doesn't need on -the -job training the moment they get into the governor's office. [12:38] Well, let's think about our commuters and what they would want to see. I know that they want to see roads, bridges, highways that work for them, that let them get to work, that let them pick up their kids. They don't want to have potholes that ruin their vehicle tires and wheels. They want to have roads, bridges, highways that work. So I would say, let's take a look at all of the above. Whatever works, I'm not going to let our transportation infrastructure crumble. We have to make sure it's working for all of us. And so let's consider anything that works that the public can get behind. That's how I would do it. [13:15] If we see that that's one option that people support, I would make sure that we are funding our infrastructure. We can't let that go because what we have is when we let our roads and our bridges crumble, people suffer, commuters suffer, and we pay a higher price. So we will fund our transportation infrastructure. [18:31] Frank, I would say that the governor has made efforts. We've seen him come down to Los Angeles, actually go out and try to clean some of the streets. On effort, I would give him an A. Here's what I would do that's different, though. I would focus on accountability. I would make sure if we're sending billions of dollars down to the local communities, to our cities and our counties, that we would demand accountability for the dollar that we're gonna give them. We need to see results, and results are what you see on the streets. We need to pull folks up, help get them back on their feet, and that's what I would do. But what I will tell you is my principal job as governor, and I'm glad to hear other people are saying this, is I'm gonna keep you housed. If you are in a home right now, renting or owning, if you lose your job unexpectedly, or you have a medical emergency, and now you're about to become homeless as a result of that now unaffordable expense, tell me what you need. How can I help you keep your home? Because it costs me so much more money to pick you off off the streets, provide you with the assistance in the shelter than it does to keep you in the home that you're already paid for. Mr. [19:45] Yeah, Frank, we spend billions, tens of billions of dollars right now to try to pull people off the streets. Do you think it's working? It would cost us a fraction of that amount to help someone who temporarily lost their job stay in the home. If they for two or three months fall behind on the rent, they don't get kicked out because we'll try to support them. If you have a zero interest loan, you can keep them in their home. I save a lot more money by keeping them in the house than watching them hit the streets and then try to find them and pick them up. Far more expensive. [24:19] Well, it's interesting to watch someone who has served as a talking head on a Fox News program telling us how government should run when he never has run any government in his life. And it's fascinating to see that he can do all these things when he's talking about not collecting any revenue to be able to do any of this work. It doesn't add up. The math doesn't work, but then that's what happens. You can be a talking head and not worry about the consequences of what you do. [29:42] Thanks, Nikki. Yeah, you hear rumors all the time about all sorts of things. Rumors are not facts and the caucus, the Democratic caucus is not a place that adjudicates those things. It's law enforcement that does. If someone had come forward, we could then have investigations. I say that as the former attorney general for the state of California. When I was attorney general, we did go after sex trafficking. We did go after those who abuse of young women and take advantage of them. We did prosecute people. There was an individual who was a religious leader who was taking advantage of young women. We prosecuted that individual. Today, he is in jail for his crimes. We have gone after people, but we go after them based on evidence and based on facts. Unfortunately, we have a president today who would go after someone based on rumors. That's not the way we do it in America. We have to have the facts. Rumors are one thing, but getting the facts really gets you to move. Let me just applaud those courageous survivors who stood up and told America what the truth was. And today, Eric Swalt was facing accountability. [40:04] I would definitely push back on the Trump administration on again, a reckless policy. I would make sure that that officer understands that he cannot discriminate against any driver without having a basis to do so. I understood a little bit of what that individual was trying to say. I couldn't see the signs, but it certainly sounded like he was trying to describe what that particular sign was trying to represent. And so we have to be very careful that we're not profiling consumers in California, drivers in California, it is against the law. And our police officers, while they try to do the best job of keeping safety, have to understand, they have to abide by the rules and treat everyone, every motorist the same way. And so if that officer had some basis to be qualified, let's take a look at that. But let's not find that people are being discriminated against because of what they look like. Is that officer asking everyone he pulls over to explain those road signs or is he asking only people who look like me? And if he's doing that, then he's violating the law. [41:05] As far as I know, the Academy does not train CHP officers to be giving English proficiency exams. So that officer has some explaining to do. [49:46] What we need is the best person who can fight those who are attacking California like Donald Trump, someone who's actually taken on Donald Trump, not just fought, but won, not someone who just wants to fight to do more for housing but has and can improve the lives of so many people, has fought for better healthcare. I will support that Democrat in the runoff. Mr. Becerra, thank you. I'm hoping I'm the one that's there. Mr. [52:38] California is going through a crisis and we need someone who knows how to govern in crisis, not someone who's gonna need training wheels the moment they walk into the governor's office. This is a time to have someone who's actually fought those crises, whether it's the manmade crisis coming from Washington, D .C., or whether it's the cost of living crisis that we face here at home. We need someone who's actually fought and won. Beat back Donald Trump to save the Affordable Care Act all the way to the Supreme Court. Beat back Donald Trump in preserving the DACA program for dreamers. Been able to do that and win for the people. [57:18] Well, we have to give those who build the homes the incentive to do so. That means streamlining the regulations and the fees that make it impossible to believe that they can make these projects pencil out. Once we do that, we wanna build smart. We wanna build in the places where it makes sense. Buy transportation so it's easy to get to and from work. Make it so that we don't have commutes that are hour and a half long. We wanna make sure that we help those who wanna buy a house get in a house. Most Californians who are renting are essentially paying a monthly mortgage, except it's called rent. I would convert them into homeowners by helping them with their down payment. We have down payment assistance programs where we will expand the opportunity for a renter to become a homeowner. And the next thing I will do is in the first 100 days, I will make sure that we get all those projects that are essentially shovel -ready, ready to go. And there are some 40 ,000 housing units that are shovel -ready. They just need a little kick over the finish line. I would make sure we do that, whether it's the small tranche of money they need or getting rid of some of the licensing requirements they need. [63:22] It's very rich to hear from someone who's never had to actually run a government. I have had to balance four budgets over the course of my time as Secretary of Health and Human Services. A budget, by the way, that was larger than the budget of the state of California. When I was Attorney General of the state of California, I had a fight, whether it was a corporate attempt to try to take advantage of Californians or whether it was the Trump administration. I got in and I filed lawsuits. They weren't frivolous lawsuits. I won most of my cases because I knew how to put down the details and the facts. So it's easy to say, you haven't done this. It's easier to prove that you actually have. [64:30] Ashley, one of the things that I will do immediately is I will freeze utility rates and I will freeze home insurance policy premiums because I believe it is time that Californians had an understanding of why so many of them are paying so much for both of those charges that they have when they have a home. It is time for us to get behind the curtain and understand why these industries are charging Californians so much and in some cases dropping Californians from their insurance policy without explanation, charging twice as much. It is time for us to freeze those so Californians benefit. [74:21] I won't be as lenient as some of the responses you've heard. I believe that it's time that we get behind the curtain and find out how these insurance companies are operating, because there are still people in Altadena and Pacific Palisades who have not been paid on their claims from back in January, 2025. That is ridiculous. Every month they paid their premiums. Some people had never filed a claim, yet when they finally filed this claim for these wildfires, they still can't get an answer to the question, how much they get and when they'll get it. That is not right. We should hold their feet to the fire. I'll make sure that we take on all the issues of wildfire mitigation. Sure, you have to harden your home. We have to make sure we don't have developers building in high -risk areas. We'll do all those things. But first and foremost, insurers owe those consumers, those rate payers, I'm sorry, people who paid their premiums responses. They paid their premiums. They are owed a response on their claims. It's ridiculous that people have had to wait more than a year. That is not the way you treat a customer. [79:52] Addiction is dangerous. Yes, I would absolutely work with legislators to make sure we can enact such a law. Kids have died as a result of their use of social media. Kids are going into this spiral downhill where they're not doing anything but playing with their phone. It is time for us to act and I will tell you as a former attorney general, I will enforce that law to make sure we are able to manage our children's development over the lifespan. And what I will tell you is this, we also have to help those families that are trying to manage their kids' use of these types of devices. [81:57] I wish I could tell you that I have time to watch streaming shows. I can't tell you that I'm much of a TV watcher.

---
snapshot_id: 34f955b2-022b-502c-9acc-c88c179baf71
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/f53b0041-4efd-41f8-a96d-949294a09a6e

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## Political Breakdown (KQED News) - Interview with Xavier Becerra - OTR page: https://ontherecord.empowered.vote/meetings/f53b0041-4efd-41f8-a96d-949294a09a6e - Video: https://www.youtube.com/watch?v=0-bhl_OtmWY - Date on On the Record: 2026-03-05 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:00] It's a hollow gesture to pass Prop 36 and not provide the funding for mental health services, drug addiction services. Because essentially what you're saying is you can incarcerate all these folks. No. Californians are done with just putting people away behind bars. Cause they know they're eventually gonna get out, most of them. And so we'd rather have folks who are rehabilitated or who are provided the services they need to stand up again. And that's what Prop 36 said. And so absolutely fund it. Yeah. And if you don't, find the money. Let's find the money. If that means we have to raise more money, revenue, then let's raise revenue. [1:30] Scott, great to be with [1:40] Politically? Well, I'm the same person. I, I am personally, I'm the son of immigrants. I have an experience of someone watching two hardworking individuals who never had a chance to go to college, who worked very hard, made very little, but somehow made it possible for their four kids to achieve things they never got to see. I am politically the son of those hardworking parents who recognizes that I have to open the same doors for that next generation of kids so that the next generation of construction workers and clerical workers who are married together will have the chance to do what my parents did, send the, their four kids to college or the military, actually buy a house. And then when it came time to retire, not have to think about going to Idaho or Arizona, but stay here in California. [2:43] Nothing but hard work. They just said, you're gonna prove yourself by your work and so just do hard work and that'll pay off. And they were saying that because that was their experience. They just worked hard and never got a whole lot. But they got a place to live and they got a place for their kids to, to prosper. So they weren't expecting a whole lot. They couldn't tell us what we could grow to do because they never got to experience so many things. But they knew that if we worked hard, we'd have a chance in [3:20] roost? So I was a third of four kids, three sisters In a Latino home, often times the child male gets a lot of preference. It used to be the case, maybe not so much anymore. Fortunately I have three daughters and didn't have to worry about that. We loved them all equally. And they're all phenomenal. But, you know, it's [3:39] one of those things where we were a close-knit family. We did a lot of stuff together. cause we didn't have a lot of money to do it elsewhere. And you just grow up around each other and you grow up weekends, you're spending your time with your cousins at your grandparents' house. And it's a great childhood. Now that I think about it, we were latchkey kids when we'd come home from school. Mom and dad were not there because they were both working, but they didn't have money to pay for childcare. Who has money to pay for childcare today? And so you, you, you bring with you a lot of experiences. So when you raise the question, who am I politically, I really am the person I grew up. I, I lived in my politics so much of what I grew up with. Three [4:32] And you know, it's interesting because I've learned stability, honesty. [4:48] And I'd say it's [4:52] a humility, but it's not a humility that you're shy. It's a, you understand that life has never been as fulfilling for you and you have to go out and make it happen. And for so many women who've been so talented and always been told, you're, you gotta wait, you gotta do it second, they've learned to persevere, to be thoughtful and to recognize my time will come. And it sure helps to be surrounded by women. Most of my staff where I've worked, have also been female. And I, I think it's a, a very sobering and edifying experience to, to get to see how the other half of the world really can not just function, but ultimately start to rule. [6:02] abortion? Ah, that's a great question because raised Catholic and my mom still prays the rosary every day. The sanctity of life is something that's really ingrained in you. Then you realize that for so many Latinas that pregnancy changes their life experience, their opportunity. And in so many ways, so many of the women who re receive abortions are Catholic Latinas. And many of them never get the abortion. And they have wonderful families. Some of them end up not getting to fulfill their wish of going to college and all the rest. But what you do learn is that at the end of the day, that it's pragmatic part. It's the thoughtful part. It's that humble part of being a woman with those experience that helps drive that. So my wife, who's an obstetrician gynecologist, a high risk obstetrician gynecologist, and a a and a adamant defender of a woman's right to make a decision with her body and who's Catholic, recognizes that if you trust a woman, she's gonna make the right decision with regard to that pregnancy. You don't have to worry about politics and you don't have to worry about men. Let that woman make the [7:34] secretary? You know, Scott, quick story. When I graduated from Stanford undergrad, my parents finally revealed to me this notion they had, they said, you know, we didn't want to tell you this before you'd graduated, but when you started work, I started working in construction with my father at an early age. And they said, we were so afraid when you started working construction that you would be so enticed by the high wages of working as a laborer in construction, that you would never go on to college. Now you have to recognize that laborers in construction don't make a ton of money. But for my mom and dad, union wages, that was good money. And so they were concerned that with that good money, I'd say, hey, I don't need college. I, I can make it, make it go it the way it is. That was never a thought of my mind, but for them, what how, could they expect from me? What were, what were their desires from me? They just wanted me to get ahead and however that would be, they were fine with [9:20] office? Right after undergraduate studies, I went to work in the state Capitol as a fellow, a Senate fellow. And so I had the experience working in the state Capitol, enjoyed the policy work, went off to law school, went on to work in the Attorney General's office. And that policy work that I had done and working for a state legislator gave me a chance to meet a lot of folks in the Los Angeles area who, after I had worked for the Attorney General's office for about four years, came to me and said, Xavier, you, never indicated it, but if you're interested in running for office, we'd love to support you. And I had really not given it much thought, but when they posed it and said they'd help out, I, I said, well, let, let's try it. And it [10:26] Yeah, and Scott, I gotta correct you. I had, I had more than just some wins. I had almost all wins. [10:32] so? It was, it was up there, yeah. It was really high. And I mean, there were some significant wins, but what, what do I remember most? Which are the wins that I, I really appreciate being able to talk about. Well, today there are, the Affordable Care Act covers some 40 plus million Americans, and it covers even more Americans, if you wanna talk about those who have a pre-existing condition. But they have their own insurance. Pre-existing conditions are no longer allowable under federal law. So you cannot, as a insurance company, discriminate against an American who has a pre-existing health condition and deny them health insurance coverage. And so the ACA I was the Attorney General who took that case, defended the ACA against the Trump administration all the way to the Supreme Court and won the DACA program for Dreamers in, in America. And California has more dreamers than any other state. These [11:34] That's right. The DACA program created under the Obama administration. Trump tried to get rid of the program, the DACA program, and most people didn't think I could win because that was an executive order by President Obama. And so any president can take down an executive order, but I, I still sued claiming that the way Trump was doing it was not legitimate. And we went to the Supreme Court and I beat him again. And so those are two major victories. But the clean car standards that allow California to have a higher standard when it comes to vehicle emissions, we protected that healthcare access, reproductive care. We protected that. ICE intrusion forcing the state and our local law enforcement agencies to do ICE raids with ICE. We stopped them from forcing us to do that. I can go on. That's a long list. Yeah. Long, long list. [12:38] one. I didn't. I didn't in [12:49] Well, honestly, I had mentioned to the Biden team after the election, before he had become president, that they'd need and worry about asking me about something in the cabinet unless it was Attorney General. I was AG in California, I was having a really successful career as AG and I didn't expect that I would leave unless I saw something like US Attorney General in the offering. And so I said, no, so don't worry about coming to me. But when they offered a chance for me to serve as Secretary of Health and Human Services, having done so much work in Congress on healthcare, having as the Attorney General done so much work, reproductive health, ACA as a AG on health, I, I couldn't just look away and recognizing this is where people are amazed. The Department of Health and Human Services is massive. It is the largest public health enterprise in the world. It has a budget bigger than the Department of Defense. In fact, it has a budget bigger than the Department of Defense and the state of California combined. You do so much Medicare, Medicaid, the Affordable Care Act, NIH, FDA, CDC, So there's so much you do. I said to myself, what an opportunity. And I've always said, if I can make a bigger difference, that's where I'll be. [14:27] - Well, the, the, how should I put this? The launch and the directive for COVID, and remember when President Biden got the keys to the White House from President Trump on January, was it 21st? 2021, more than 4,100 Americans died that day alone. It was, we were in a real crisis. And so the Trump administration left us a mess. The Biden administration before being sworn in, was already on the job. And so they had assembled a team working out of the White House. So when I came in, in March of 2021, there was already a full fledged team working with our HHS personnel at the White House. And much of the decision making, as you would assume was gonna be done at the White House for the biggest peril that our country had faced in what, a [15:26] I, once I became secretary, I was included, I was part of those meetings, obviously, because most of the team working on this stuff, Dr. Fauci and the rest came out of HHS. But clearly the White House was really working with the president to make sure where we went. We executed, like, let's put it this way, HHS, I as secretary. We executed the Biden administration policy on COVID at eventually by the end of 2021, we migrated over the entire operation, which was at the Department of Defense over to the Department of Health and Human [16:34] No doubt I'm gonna have to do more social media, because that is the principle way to communicate today with so many people, including voters. And it's a lot less expensive than trying to do it simply through the TV networks and cable news. Those are the old fashioned ways. So absolutely, you gotta do more of that. But you're right. I, I am not the shiny object. I am not the flame thrower. [16:58] a whiteboard. I, what I do is I get my work. You know, I go back to what I said about my parents. They just wanted me to get my work done. Let your your, let your work product prove who you are. And that's what I've always done, is I've always let my work product prove who I am. And while the White House was calling so many of the shots on COVID, we were the ones at HHS who were executing. [17:57] done? You gotta fund it. I mean the, the, people California spoke and they're right. It's a hollow gesture to pass Prop 36 and not provide the funding for mental health services, drug addiction services. Because essentially what you're saying is you're gonna incarcerate all these folks. No, Californians are done with just putting people away behind bars. Cause they know they're eventually gonna get out, most of them. And so we'd rather have folks who are rehabilitated or who are provided the services, they need to stand up again. And that's what Prop 36 said. And so absolutely fund it. Yeah. And if you don't, find the money. Let's find the money. If that means we have to raise more money, revenue, then let's raise [19:09] Taxation policy should not be a one-time deal. And so the initiative that's on the ballot, I think rightfully targets the mega wealthy, the billionaires who have made a killing in California and haven't done their fair share. But you don't need tax policy to be a one-time shot because you need consistent, predictable revenue in order to manage a budget the size of the state of California. And so that's not tax policy. I'm saying that to you, not just because I don't believe that's the best way to do policy. I'm saying it to you because I was for 20 years on the Ways and Means committee in Congress, a tax policy writer. The Ways and Means committee does all the tax policy in the House of Representatives. Tax policy has to be predictable. It has to be stable. And it has to understand that it's interconnected with everything that goes on. And so we will have revenue, we will raise the revenue we need, but we'll do it in a predictable, stable fashion. [20:12] Well, I would say that baseline way to, to explain it to average California is to say if you are mega wealthy and you're paying at tax rates that are lower than a nurse, a teacher, a firefighter, a police officer, then you're gonna end up paying more when I'm governor because it's not Fair. How, [20:31] how So principally it would be looking at some of the passive income, some of the investment income where, which is where so many wealthy individuals make so much money and pay very low tax rates for that investment income. [20:49] Well the federal government could deal with it, but the feds are gonna keep that money that they raise through federal taxation. This is for state and we, we can do something very similar. [21:14] Yeah. I mean, what is it that Japan, China Europe, everybody can build high speed rail, but the fourth largest economy in the world, California can't, no, it's, that's not the problem. High speed rail makes sense. Talk to all those countries and all those communities that get to move around at fast speed on a train rather than have to always worry about getting on a plane. It absolutely works. It doesn't work though. If you launch a project, you don't have the full support of communities that are gonna be impacted. And the way those communities express that is by going to court and stopping your project over and over and over again. Litigation is expensive. Delays are expensive. And that's what we've encountered. So when I become governor, we're gonna get rid of all these delays in the litigation. I'll sit everybody down who's got some concerns and we will resolve it. But we're gonna build high-speed rail. [22:11] yeah. You know that, look, I found this in so many cases dealing with COVID, trying to get 50 states to be on one, one on one track with us on [22:21] COVID it's tough. 'cause remember the federal government doesn't run healthcare. States do. I had to get 50 states to be on the same page when it came to distribution of vaccines, distribution of paxlovid and all the treatments. It's tough, but you gotta sit everybody down and you don't do it mid-track. You do it at the beginning before you take off. Yeah. [23:20] Well, Scott, don't forget I litigated those policies. SB 54, the Values Act. We defended that in court against the Trump administration the first time that they came after us because of SB 54. And we beat him back. It is constitutional. The state has a right to police do policing authority, not the federal government. has a right to do immigration enforcement, but they don't have a right to do public safety. And what you find is that this ICE is doing far more than just trying to go after somebody for immigration law violations. It's become clear. That's why so, many Americans have now died at the hands of ICE. We will defend it, we will win. Because of the Constitution. ICE is not a policing authority in the state of California. They are an immigration enforcement authority and they must limit themselves to that. If they don't have a warrant, they don't have a basis to be going all over the place in California and just tracking down folks or stopping [24:57] Free Country Democracy. If that's what you think is the best way that you can leverage to stop an entity, a company from doing things that you think harm your neighbors or your state, go to it. I have no problems with that. You have every right to say that you don't have the the right to tell a company not to operate in California. But you could say to somebody, Hey, you should boycott that company because this is the way it operates. [25:24] I'm, I'm not going out there to search for their money. I'm not looking for their [25:30] it? I doubt they're gonna hand me a check. I was one of the guys that was suing on some of these activities. Fair [26:01] What counts is that the votes are counted and they're counted right. We want everyone to vote. And if that means that we're getting ballots that are coming in postmark timely, but coming in the day after or a few days after, so be it. We want your vote to count. If you're a, a soldier working abroad and you barely get your ballot in by postmarked in time, why don't, why would I try to keep your vote from counting? No, absolutely. So long as it's counted and it's counted right. Yeah. Amen. [27:03] Yeah. And gut punch, as I said, never expected it. But here's the thing, you know, whether it's as AG or Secretary of Health Human Services or it's governor, what matters isn't how close you are to someone or how long you work with someone. [27:23] The law is the law and no one is above the law. And so Did betrayal? [27:28] It was something I didn't expect to see. And what I will say is that having served as AG, the authorities have a, a obligation to investigate that thoroughly and then come to some conclusion and every chip fall where they may and, at that point, for me, it was one of those things where it's not what you expect, but again, you keep moving forward. [27:57] My mom's house. Do you [28:03] gosh. You want some Chile verde? Would you like some barbacoa? Would you like she makes a mean fried chicken. You know, it's my mom's house. My, my wife's pretty good too, although it's a little healthier than my mom. But yeah, if I want someone to eat some really good California cooking my mom's house. All right. When we come, [28:24] we

---
snapshot_id: 891dfa2b-5d25-527d-8119-d90966da707b
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/4d53e045-cf54-4679-896a-9b162d22f6db

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## Xavier Becerra - The Race for Governor - Commonwealth Club World Affairs of California - OTR page: https://ontherecord.empowered.vote/meetings/4d53e045-cf54-4679-896a-9b162d22f6db - Video: https://www.youtube.com/watch?v=ecFBZY73WB4 - Date on On the Record: 2026-02-10 - Kind: forum · Candidate Forum · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:04] you. Yeah. That's. [1:09] Thank you. Thank you very much. [1:38] You know, it was a great upbringing. I thought I was middle class, all the way until the day my mom and I, I drove my mom to Stanford to help me enroll in my first day at, the university. And as we're driving, we go through Palo Alto. And then I realize that I did grow a bit of class. But I didn't know better, because while we never had much, we had what we needed. And I again paid tribute to my parents for never making us feel like we were anything but kids who were going to live a great life. And I was very fortunate my father didn't get past the sixth grade because he was the oldest of eight and had to start working right away. [2:20] When he married my mom and they came to California, they had $12 in their pocket and they worked pretty hard. He started off at that point working in a Campbell soup factory, canning tomato. And my mom was quickly learning English and then began work as a clerical worker. But, construction worker for most of this time, my father was. And then my mom. Clerical worker. Somehow they figured out how to buy a home. But in those days, in 1950s in Sacramento, they were able to buy a little tiny house, tiny, house for $6,500. Yeah. And I know we laugh today, right? You you can't even put down a deposit for that, let alone the down payment. Might be sisters and I, we had the chance to all go on to college or serve in the military. My dad, because he was a union member, had, health care for the family. And, today, my mom is still alive. My father's passed. My mom lives with my wife in me. And, they were able to retire here in California. Not have to leave and go to, you know, Idaho or Arizona, and I, I look at that and I did not know what they were doing for me, but what they essentially gave me was this path to know what to do with my life as a state legislator, as a congressman, then fighting as the attorney general for people in California, then as secretary. And, and now, I hope, as governor to help the next family. That's a construction worker, clerical worker that wants to have an opportunity to do for their kids what my parents, with no college education whatsoever, had a chance to do for theirs. [4:06] It's it's it's home now. My wife and I live there. My wife's a high risk obstetrician gynecologist. She works at UC Davis Medical Center there in Sacramento. I get to take care of my mom. My father passed in my home. I I've spent more of my years in Los Angeles. I spent quite a few years here in the Bay area, obviously for school. Sacramento is a great town. I'm still a Giants fan, even though I represented the Dodgers for 20 some odd years when I was in Congress and I became a Dodger fan as well. It doesn't hurt to be a Dodger Giants fan. They weren't quite a few of the World Series over the last couple of decades. [4:49] Oh, you shouldn't have asked that because I'm you. Open the door. I'm going to lose the California votes because, you know, you're you never lose your childhood loves. And, at the end of the day in San Francisco, I got to see on TV Willie McCovey and Willie Mays play. I remember Dave Kingman. I remember Bobby Bonds. Not just Barry Bonds. And, so you go back a long ways. Do [5:16] I'm thrilled that they are in Sacramento, but, I barely have time to get some sleep, so. Okay. [5:38] Actually LA pretty much la, San Gabriel Valley area of Los Angeles. I started working after law school with, a state legislator in Sacramento doing policy work. He was a legislator from us, from Los Angeles, and at one point this was 1986. He said, my chief of staff have you're my chief of staff, has moved over to work on mayor Tom Bradley's campaign for governor. I need someone to run my district office by senatorial office in Los Angeles. Will you come? I've been to LA to work. While I was going through law school, and I said his name was arteries, Senate arteries. And, Yeah. You remember Senator Torres? Yeah. And, I said, Senator, I came to do policy. I want to be here in Sacramento. I said, it's temporary. Just until the election, till Mayor Bradley wins, becomes governor. I said, okay, I'll go down. And, in the process, I got to meet lots of folks in the community. I after that, after 86, I went to work in the attorney General's office, which I ultimately got to become the AG of. But I worked there for about 3 or 4 years. Lo and behold, the people that I met in 86 working on their behalf as, the aide to the senator approached me and said, have you have you ever thought about running for office? And I said, no, not really. I was really happy at the AG's office. And they said, well, if you decide to run. We'll support you. I said, well, let me give you some thought. And this was like on a Friday or Saturday night. They treated me to dinner and they said, well, just hurry up because the filing deadline deadlines on Tuesday. So I made a quick decision, decided to run, got won a race, came out of nowhere in 1990 and and two years later, 92 got to Congress, served 25 years. Representing Los Angeles. Do you [7:27] You know what? I, I thought I would not leave Congress. And when then Governor Brown in 2017 or 2016, approached me and said, would you consider being the attorney general in California? Cause I don't want to leave Congress. I'd been there for 24 years, but, you know, I always say to myself, if I can do make, make a bigger difference somewhere else, I'll go. Otherwise, I'm going to continue doing what I'm doing. And I took a chance. And I'm glad I did become the attorney general, because I did have a chance to make a bigger difference. I became attorney general. I got sworn in a week after Donald Trump got sworn in to be president. So I was very busy. My four years as attorney general. Four years. [8:34] You have to make good decisions quick, and you have to be prepared to bring in talent that can give you the chance to know what to do. I would always tell my teams as the executive, don't come to me and tell me what we have to do. Come to me with the things I can do and give me the three best options. Then tell me the one you think I should take. And once you give me the three options, I can weigh them. And chances are, I'm going to go with when you've told me because you probably made the assessment. But let me make that call. But always give me at least 2 or 3 options. And that's what my teams, when I was secretary of Health, Human Services and as AG would, would do. And in both cases, whereas in the case of AG, we ended up having to sue the federal government, over 120 times because they were really coming at us every direction. Some of the stuff that you're seeing today with ice, they tried it the first time and we were able to stop them the first time. They got more aggressive this time. But when, President Trump tried to send down ice and tell ice, try to tell our law enforcement that he had to join in their immigration raids, I said no. And because I said no, they then went after $57 million of community policing dollars that California had received in grants, and they denied us that in both counts. I had to take them to court on both counts. We won. We didn't do Ice raids, and we got our money back and so we just had to constantly be ready to go after. [10:13] just can't be doing more. Just had another victory today. I don't know if you heard, proposition 50, which, was contested by the Republican Party here. They took that to try to take it to the Supreme Court. just rejected, rejected the Republican, attempt to have the court reconsider the case. And so, AG Bonta just got another victory. So he's he's working hard. This is a a different Donald Trump, more aggressive Donald Trump. But, you know, as as Rob said to me the other day, he said, you gave us a playbook on this. And so I the day that, Donald Trump sent in, Ice officials and then the National Guard, I, I said in some, interview that'll be struck [11:01] down because we went through it as well. And it's it's not legitimate. You cannot do that. And so much of what they're doing, they tried before, much of why they sometimes succeed against us is because you got more conservative courts. [11:22] Yeah, [11:42] What I've experience been, President Obama made an offer to me when I was still in Congress, to serve for a time, and I decided to stay in Congress at that time. But typically, what happens is you'll be approached, they'll ask, are you interested? And I signal pretty early on it. You know, I'm really enjoying what I'm doing as attorney general. So you really don't have to worry about me unless you want me to be the U.S. attorney general. Then I'll consider that. [12:08] And so, they would stay in touch periodically, and at one point, they did say, you know, would you consider Health and Human Services? [12:18] And I thought I was set in staying in California, but having served in Congress, I did a lot of work on health care. I did I was one of the drafters of the Affordable Care Act. I did a lot of work on the Ways and Means Committee on Health Care, especially financing, and I knew it really, really well. And I know how much you can do. HHS intrigued. And when they got serious, I got serious, to give you an idea, the California Department of Justice is the largest, state Department of Justice in the nation. No state, not even New York, comes close. [12:56] I had a budget of over $1 billion. That was pretty big. My budget at Health and Human Services was $1.7 trillion. I tell people as I'm running for governor, I'm the only candidate who's actually managed budgets and balanced budgets that are as big as the budget of the state of California. The budget of the city. California is big. So is, for example, the budget of the Department of Defense. You can put the Department of Defense's budget in with the state of California's budget, and together they are still far smaller than the budget of the state of the Department of Health, Human Services. That's because we've got Medicare, Medi-Cal, National Institutes of Health, Food and Drug Administration, the centers for Disease Control, protection, Head Start. This goes on and on. It's a huge operation, 90,000 people. And, you have to make tough decisions. So on the question, is it different being an executive than it is being a legislator essentially a board member of a board? [13:59] Yeah, it's very different because they're your calls and you have to do them right. Setting up 700 million Covid vaccinations to Americans throughout the country was not an easy task. That's what we did by the end of the four years that we were there, we had essentially gotten some 700 million Covid shots into the arms of Americans. But what I'm most proud about is that we never charge any of you a penny for those vaccines. Try try getting the vaccine now. If you don't have insurance, you now have to pay. [14:56] Yeah, it was a full blown, full blown crisis. What if I said to you. Yeah. Did you hear the news that a jumbo jet crashed and everyone on board died? one. two. ten [15:08] It wasn't It wasn't It was jumbo jets that crashed, and everyone perished because it didn't happen today. But during Covid, that's what was happening every day. About ten jumbo jets of Americans, about 400 people per jet, would crash and everyone would die. Because when Donald Trump handed the keys to Joe Biden in January 21st, 2021, more than 4000 Americans died in one day. That one day from Covid, we were losing thousands of American lives every day from Covid. We don't remember that, but that's where we were. If I had said to you that ten jumbo jets crashed, you'd say, what is going on? But because it was Covid, we didn't treat it the same, but it was a full blown crisis. And I said it at the beginning, if I can be in a position to make a bigger difference, that's where I'll go. That's why I took the position at HHS, because it was clear you I was going to get to make a big difference. [17:04] It, those are those are some of the salient talking points that were being used at the time. So I think he just sort of plucked them out of some MAGA press release and, and inserted them into his piece that he's running for governor. I mean, it [17:20] wasn't. But it was an article that didn't say what the MAGA piece said. The article talked about how kids, unaccompanied migrant children who when the Department of Homeland Security, a detain them, could not hold them by law. they are an agency that detains adults and incarcerates adults detains adults. By law, they must transfer them to HHS because we are more equipped to handle children. And so those kids would be transferred to us by law. We're supposed to place them in the least restrictive setting with a family not in some congregate care facility. And so we search for sponsors, reliable, vetted sponsors, and that's what we did. The New York Times article dealt with the issue of some of these children not reporting to Ice when they were supposed to because they were there still with an immigration case that was pending and some people characterized as kids being lost because they hadn't gone in for their immigration hearing. And they were talking about something like 85,000 kids missing or lost, which of course, MAGA MAGA bullets exploded into something huge. By the way, if it was something true, and they were so concerned about it back then, how come you don't hear about anybody searching for 85,000 lost kids? [18:51] not true. The [18:56] They were again, the New York Times was going off of some memos that talked about how we were getting a large number of kids, if you remember, in those days, and they were having to try to move quickly to try to find them vetted sponsors. But we never short changed the process, because you still have to go through a vetting process to make sure that anyone who's going to take care of a child has passed through those criminal background checks in the rest. And so and if the New York if that was true, why hasn't that New York Times reporter followed up? I went through a number of hearings where Republicans in control of the House sat me down and essentially grilled me on the whole thing. [19:34] Yeah, she did. She wanted more information. But as as she's talking about 85,000 kids that are lost, I mean, if you cared about 85,000 lost kids, then shouldn't you care about 85,000 lost kids today? [19:50] Well, because I'm ahead of him in the polls and you got to bring down the people are ahead of you in order for you to come out [19:58] That's basic policy in no one. Yes, but there [20:13] Yeah. We've known each of these for years. Again, for decades we've had Anthony and I go back a long ways. We were very close friends for a time. [20:21] Okay. Like, get [20:27] at me. But I should just close on this one point again, taking on tough challenges when I became secretary, and that was one of the tasks that we had, is to receive from, Border Patrol. These children who had been unaccompanied at the border. We had a task to stand up facilities that could offer them the licensed care that we, by law in this country, we must provide the difficulty in this whole process, which the New York Times tried to it essentially touched on a bit, was the fact that the Trump administration had dismantled the licensed care network that had been put in place by previous administrations to care for those who needed special care because they were not adults and couldn't stay at the Department of Homeland Security facilities. But they dismantled that. And so there was not the licensed care, practitioners or facilities to care for these children. That created a real tension to have to try to figure out how to provide the correct services and make sure we could process the the application for these kids to be able to go to a vetted sponsor. We did what we were supposed to do. It was under trying circumstances, but we did. Now you got the Trump administration again, and they are once again dismantling the system. And that's why you see a five year old be transported by department of Homeland Security, not by HHS, separated from his families. They are going back to what they did before. They are not following the law. They have dismantled the system that's supposed to be there for children, and they're treating children as if they were adults in violation of the law. They're the root cause of all of this was that the Trump administration dismantled a system. And the Trump administration today is going back to dismantling that system. [23:14] So this is where having that breadth of experience really comes in, having grown up the son of immigrants, having worked for immigration reform in Congress, having served as the attorney general who defended immigrants against Trump, won attacks, including, for example, defending the DACA program for dreamers all the way to the Supreme Court and beating Trump in the Supreme Court and keeping it alive. And then if serving as HHS secretary, where, as I mentioned to you, we made the Covid vaccine available to everyone, regardless of your income, zip code or status. [23:57] So when you asked me the question about it, I said, well, I'll give you the answer that I, I, I believe in my heart. And I've said publicly, we need immigration enforcement. We are a sovereign nation. We have a right to know who's coming into a to our through our borders, and we have a right to enforce a law. But this ice that we see in Minneapolis, that we've seen in California in this way, they don't belong anywhere. That law enforcement does belong anywhere. And so if we're talking about what we're actually witnessing, that does not belong in America. But do we need an immigration enforcement agency? Yes, we do. And I say that. Have you been the top cop for the state of California? As the attorney general, where I oversaw law enforcement in California and every day I worked with Ice at the same time, I sued Ice for violating the law. I mentioned in that debate yesterday that I have taken down sex trafficking rings. I have taken down organized crime syndicates, and in each of those cases, I can probably point to you at least one, if not more, federal law enforcement agencies that were working with the state of California and our local law enforcement agencies to to do that work. We work with them every day. We have to work with them. You can't do drug interdiction without talking about federal law enforcement working with you. And so my division of law enforcement at the California Department of Justice works day in, day out with federal law enforcement, Ice, DEA, the FBI, the marshals all the time. We do some good stuff with them. What you're seeing on television is not the stuff we did with them. None of their officers, their agents, would wear masks, conceal their identities. Come in unmarked vehicles, that is. That's not the mark of a legitimate law enforcement operation or agency in the United States of America. And so what we're seeing, I don't blame people for wanting to say, get rid of ice, but we do need enforcement of the laws and we have to do it. Right. So, yeah, what Trump has put on the on the ground. Absolutely get rid of it. And they're violating constitutional rights. But we do have to have an agency that can oversee and enforce our laws. I want [27:16] It's penny wise to try to deny someone health care. Because at the end of the day, if your child is hurting. Yeah. What's your child is hurting? You're going to take them to the hospital even if you don't have insurance, even if you don't have a lot of money, you're not going to let your child suffer or die before you. And so it is foolish to think that, health care is a commodity, that you can say, well, I my kid's hurting. I'm not going to take him to the hospital. I'll let him go play games. You don't guess. It's not like you can take one commodity and shift it for something else. Health care is different, and so to deny someone health care one is not only immoral, but two is not fiscally sound. Because what happens is when that family waits too long and it gets really bad, and when they finally enter the door for health care services, they're not entering through the pediatrician or the primary care, the family care doctor store. They're entering through the emergency room door, which is the most expensive form of care in America. And so we're paying they're paying whatever little money they have in their pocket. They will lose, and it still won't be enough to cover the bill. And so what? Guess what? We will lose as well because we as taxpayers or what typically happens is the cost get shifted. That hospital will shift shift the cost of that unpaid for care to those insurance companies that pay for care through you who are insured. That's when your premiums go up for your private health insurance. So either through your private health insurance premiums that get raised or through your taxes, you are paying for that uncompensated care. And so why would I be foolish and say, I'm not going to let you have early access to care because you can't you don't have your own insurance. I know you're still going to use the care, and so I'm not going to deny someone that access to care. I have been a supporter of Medicare for all, for decades, because I think everyone should have decent access to care. But fiscally, having served on the Ways and Means Committee in Congress, which deals with all the financing of budgets, I think you lose money when you do things late. You know, Frederick Douglass, a great American, said about 160 years ago, it is easier to build strong children than to repair broken men. In America. We spend so much money trying to repair broken men and women when we should be spending our money early to build strong children, or to give families access to health care. It's just smart. My mom said it even better than Frederick Douglass. Mijo, you my son. Better to prevent it, to remediate it. Just that basic. [30:11] the health care one is a big one because I, will I not go backwards. We did suffer big hit the trillion dollar lost to the Medicaid program, what we call Medi-Cal here is huge. And I can understand why the governor's saying I got to make do something because of the shortfall. I just wouldn't choose health care to to pick to try to take care of that shortfall from, we talked about, the response to the ice, illegality. I would have handled differently in that. I would have started from the beginning with my law enforcement leadership. Having been ag and having worked with our chiefs of police and our sheriffs of the 58 counties, I would have asked them help me talk to the people you talked that we talked to all the time. The heads of the federal law enforcement agencies in this case, Ice. And let's say to them, you guys have a right to do federal immigration enforcement. We can't stop you, but we patrol the streets. You don't have a right to do anything on the streets unless it's for federal immigration enforcement legitimately. And so if we see someone who's masked, chasing someone down the street and we don't know who that masked person is by right, our law enforcement officers should be tracking that person down and make sure one of our citizens isn't being harmed. And so we should understand the rules of engagement, because sooner than later it will be blue on blue. And none of us wants that. And I would have had my law enforcement leaders who have relationships with law enforcement leaders at Ice to say, come on, let us crack through that. Go make some sense of this, because this is not going to end well. I would have done that from the very beginning. [32:09] The Governor? [32:14] Yeah, when I got time, I do a whole lot of things. [32:34] time to pack from DC and come back home. I am doing one thing. I was approached, a number of projects. I decided to work with, UCLA has a, an initiative. It's, they call it the their voting rights project. UCLA voting rights project. It's an office, a small office where essentially they do everything they can with a team of lawyers and a team of policy analysts and data crunchers, and they try to ensure that elections are run fairly and freely and that people aren't denied access to the polling of booths. And so the voting rights project struck me as something I wanted to do, because I've done some of that work in Congress as the attorney general. And I figured I want to devote some time to that, but that was about the only thing I did, because once I came close to make the decision to run for governor, I just knew I wouldn't be able to devote much time to outside projects. Other than that, just having a chance to catch up with family a bit, there's not much more time. [34:02] That's the question for the audience. I know all the candidates. I've worked with [34:09] most, if not all of them. You know, this America. It's good to have good that, you know, a strong competition. You know, it'll start to come naturally. Yeah. California's a big state, expensive state. And, we'll see. But know when that. That's not a question for me. [35:04] Well, I, don't that there are smoke filled rooms, but I don't think they're going to come to any conclusion. And, my sense is that both the natural course of this race over the next probably two months and the reality of money are going to drive us to a much smaller field, and that's when people will have an opportunity to really, assess who has a chance to, be there, who they wish to support. But until then, the best thing I can say is voters pay attention, because what you don't want is to lose the candidate you really think is good, simply because money drives that person out. And we need to make sure that we're we are getting someone who can make a big difference and knows how to get it done. [36:06] No, I, I again, I know most of the, candidates because I've worked with them throughout my different stages in my career. But no, I don't have a, particular candidate. [37:12] Yeah. And I would see the, president pretty much weekly, sometimes for longer periods and others. Sometimes you have a cabinet meeting, sometimes you have events. Obviously with Covid, a lot of activities going on where the president would participate. And so, you know, there was always a constant, opportunity to be with a president, not always sit down necessarily with him in a small circle with folks, but at events and so forth. And what I saw was a guy from my perspective who was making some really good calls. What I will tell you, as you can see it, I could see it that he was getting older, he would get more tired. And I think it was pretty clear that the longer the day was, the more tired he looked. So by the time you got to some evening activities and they were long days at the white House, we would be doing some events late into the evening, and chances are the president had started his day pretty early. And so for anybody, I don't care if you're, in your 70s or 80s or in your 30s or 40s, it's a long day. And so I think you could see that he would get tired towards the end of the day. But was he making the right call? what he You know gave me? The the ability to put 700 million vaccines in the arms of America, of Americans and never have to make someone face the, the consequence of the, the, decision of whether or not to have to pay for it. You know, how many people would not take medicine if they had to pay for it? And I will tell you, it wasn't easy. to get to the point where I was able to enact the first rules to try to have minimum standards of staff for staffing at nursing homes. More people died in nursing homes from Covid than anywhere else in the country by a factor of about 20. It was the most dangerous place to be during Covid. [39:16] And it is clear that if you're under staff, you're not going to catch things. Never in the history of our federal government had we imposed minimum staffing standards in facilities. But we went, in this administration and showed just how bad things can be in nursing homes. And so we were able to pass regulations that required minimum nursing standards and nursing homes. That was tough. In fact, right now Congress is still trying. There's still some in Congress who are trying to undo those rules. [39:51] The president made the call to let us move forward on those things, because we knew we all knew we were going to get real heat from the industry. As far as I'm concerned, the cause that President Joe Biden was making were the ones that were helping the American people. And there was no cognitive decline in the ability to make the right call for the American people. Today, none of you have to wear a mask. You don't think about that. But today, you don't have to wear a mask. You can sit right next to each other, not six feet away. Those decisions were consequential, and those decisions ultimately had to be made, if not by the Secretary and certainly by the president. [41:14] Yeah. So we're all still sort of bunched. Even the double digit. It's low double digits. It's just, it's a scrum essentially, right now. And, with so many people in there. What really, you have to give folks that large undecided vote a chance to really get to know who's their. And my, belief is that over the course essentially of the time of the filing period, by the time we get into March, it's gonna we will start to see the separation occur between those who really have a shot into June and those who don't. I believe that I will be among those who have a shot. And it could be a crowd of its biggest five, maybe even six, probably 4 to 6. And then it's going to be a matter of who can get the grab the attention of the public well enough to prove their point. If, if folks are looking for the, show horse, the shiny new object, I'm not going to be governor, for the reasons you said. I'm not. You don't see as much on me on the internet, although no one can tell you that they've served in state legislature, Congress and the executive branch as as a cabinet secretary and as the attorney general of the largest state in the nation. But I've not been thumping my chest all that time. Just been doing my work. So if people are looking for the show horse know, looking for a workhorse. Got a good chance. People looking for a car carnival barker who gets into social media all the time. Not me. But again, if they look for someone who, when he says get it done, it gets done, then I've got a shot. That's my course. As I've said, I'm not the richest, I'm not the slickest. But if you want someone who knows how to fight and win, whether it's fight and win against the Trump administration, when I had assumed 120 times and beat him to defend the ACA, beat him to defend DACA, beat him to keep our, clean car standards, beat him to stop him from building, a border wall, beat him to keep women's reproductive health going in California, beat him to make sure that, he didn't, distort the Clean Air Act. Then I've got a shot because I just don't fight. I know how win, and we'll see. to [44:07] You. Yeah, yeah, this is politics. So yes, I got it. A quick story, I when I was still attorney general, one of the things that we do is we oversee all the nonprofit, organizations in the state. You have to file your paper. You want to be a nonprofit, not be taxed the way a for profit company does. You have to, you know, prove that you're a nonprofit. Well, shouldn't surprise anybody here that some nonprofits abuse of their status. And we go after those nonprofits that are abusing of their status and essentially defrauding people of their money when they make donations. One of those was a an organization that called itself Puppy Salvation or something along those lines. And they they publicize that they were saving, abandoned, pets. Puppies. [45:06] We we investigated them in Rome. Lo and behold, they were not doing anything that they what they advertise. So we had to go after them. And among the animals that we say we're, we're, we're a bunch of, very young puppies. And so we did a piece where we had the puppies, and I picked one of them up, and somebody was flashing photographs that went up on our social media. We did. They said, general, guess what? You had more likes and hits on that one piece than anything else you've done. So if I want to win this governor's race, I gotta have a puppy with me everywhere I go. And sure enough, I will get the vote. But, you're absolutely right. I was like, a good plan. Yeah. So, yes. Do we have people whispering in your ear all the time? You should do this. You should do that. You should attack them and do that and bring them down all the time. All the time. And it's, that's politics. You know, bring someone down if they're above you on the ladder and climb as fast as you can before they can get your feet. [46:09] Yeah. I'm very fortunate. Most people would say looking at me when I was a kid, I would be lucky to have a decent life. My parents, I started working in construction alongside my dad and road construction, and they finally told me this after I had graduated from Stanford University. They said, you know, we didn't want to tell you look at the career, but the serious, too. We never wanted to tell you this, but we were so afraid. When you started working road construction with your dad that you would leave it because the big money you were making and of course, for for a kid who, you know, never had much of anything. And my dad, you know, road construction workers don't make it, tenement laborers don't make a lot of money. But for me, that was big money. And so they thought I would you be, know, enamored by the big paycheck. And I wouldn't go on to get a university degree that's. [47:05] That's where I came from. And so to get elected to serve in Congress, to get to be the chief law enforcement officer for the state of California and defend the Affordable Care Act in the Supreme Court and beat the Trump administration to then be asked to serve in the cabinet of a president. [47:26] I could die, and I know I think it'll be heaven. I'll have some good conversation with folks on my experiences if I get to be governor, I'm going to be thrilled because I know I'll get to do some good things, but it isn't my life. In fact, in the debate yesterday, I did mention, among all the things that I had done, that one thing that I'm most proud of, of the things that I've done, is that for 37 years I've been married to the same person, my wife, the, ob gyn, high risk specialist. Carolyn and I have been together for the longest time. We raised three phenomenal kids. If there's a story of success, especially in a world of politics that I've had to live in, it's that I have a family and we still love each other a great deal. And that, to me is the best part, because I if I'm grounded at home, I'm going to be anchored really well wherever I go. [48:17] Thank [48:47] She's always been thrilled to see what I've been able to achieve. And she always, you know, looks up to the Lord. She's very religious. And she'll always say, I don't know what I did to have the Lord give me these blessings, that kind of thing. But I will tell you, after the, service in the secretary where I had to go back to DC, I think she's ready for me to not have to move around anymore. She'd like to see me a little bit more. She's a mom. I'm still here. I'm still her boy. She still blesses me when I leave. She no longer does. She. When I was still a G, she still say to me as I was getting ready to leave her to go to work with her. Do you need any money? [49:25] Yeah. And she doesn't do that anymore. But I think she'd prefer to have me around more than than I am. But she she's very proud, and, [49:40] She feels blessed. [50:02] So you have to put in perspective. My mom is. have made She would Bill gates look like a mediocre, businessman because how she was able to take my dad's [50:20] salary and, because she would started working once all four of us kids got to school. So she didn't work until my youngest sister started kindergarten. But even then, clerical work, she wasn't getting paid much. She's the. She was the brains. She was the one that decided we need to do something with this money. Not a lot of money, but she figured out how to buy a little house here. And then they bought this one property. They had five little homes on it. before you And knew it, they had this little empire. And. [50:53] For them. can't [50:57] They're they believe what they've been able to do. My my dad is now passed, but she will always say we're just so very fortunate. And then to see their son get to do all these things, they feel very fortunate. But at the end, she's still a mom and she'd rather see her son. She, she like, see me on TV, but he'd rather see me in person. And, [51:19] so she actually keeps me very grounded. [51:32] That is, it I again, for the same reasons you don't see me are posted all over social media is the same thing with my we [51:43] were pretty quiet family. You know, when you're an immigrant family and you're trying to prove yourself, you don't go out and boast a lot. You just try to let your work speak for itself. My dad was a just a phenomenal worker. You know, he never got past his sixth grade, but he knew how to do it. He knew how to build. And everywhere he went, every crew he served, every every foreman wanted my dad because my dad do everything. And so if you if you my dad was part of your crew, you just sort of make sure that this gets it. And the crew would get to work because my dad knew how to do it. Everyone wanted my dad, and they would always tell me I did. Maybe you should become a foreman. You get more pay, you run your own crew. But he said, no, I don't want the headaches. I think that was my dad's way of essentially saying I never learned how to read and write very well. I don't want to make any mistakes, so I'll just do this work because he didn't want to. make a mistake. And so he didn't want to take on trying to do the math and all the things that he to get to do. But I will tell you, in retirement, he would not put down a newspaper. [52:49] And he would watch CNN, MSNBC, and he was whenever I come back from this, when I became a and I moved to Sacramento, I had my parents move in with with us. And so he knew an evening when he put the newspaper down, I was I come in, it was like right away, did you hear this news that don't you think we should do this or that? And so he was into it. So they were they were very proud and thrilled to see what I got to do. But inside the house, it wasn't as if they were boasting what they did boast. My daughters. We made sure our daughters learned how to play the piano because, you know, it's just great to see them play piano. And my parents loved watching my daughters play piano. And so one of my daughters made a recording of many of the songs that she learned to play. And my dad, in his F-150 pickup would insert the cassette and play it. And one time one of his neighbors heard that, heard the music, and it's classical music, he say, we what music is. And he said, well, that's, that's my daughter. And you can see the pride. That's my daughter playing there. And it's, you could see how thrilled he was because, guy yeah, with an F-150 pickup with hammers and all this stuff in there. But he had his classical music playing on it on his cassette player. So it is it's great to see. And, I've been very fortunate. I'm not going to change any part of my life. I've. had a really good life. And if I get to do a little bit more, I'll. be thrilled. [54:42] So, the way I approach these things and I would be part of it is it's here. It's coming. Make the best of it. Because if we don't, we might get the worst of it. And so let's harness it in ways that work. [55:00] If you're a worker today, I want you to know that I supplement, not supplant, what you do. I want you to know that we're we're using AI to make your work better, more efficient, more productive. does seem like, It [55:37] And we can we can transition just as we're transitioning energy from fossil fuel to clean energy. We we can transition when it comes to AI, what I'm saying is, if you've got someone who's working, doing the job that now I seems like it might be able to do somewhat, that doesn't mean you jettison the worker just like that. It means you start to use AI to supplement the work of that individual when they retire. Might it be that you moved on from having a workforce as large? Perhaps. My father used to use pick and shovel doing construction. Then you started having jackhammers, then you started having these backhoes, the big machinery that started doing this. Today you have big machine, big machinery, working side by side with men still carrying shovels. But the men and women are no longer doing the same amount of work, because you now have machines that can do so much of that just the same as the assembly line. It's not a natural. So what we should do is harness it to our advantage without hurting the very workers who did that work before. And we can do that. That's the transition and the industry, at least in my book. If I'm governor, will have to work with us to do the transition, not just all of a sudden take over. And we do that. We're going to be in really good shape, and it's going to take a little time anyhow because nothing happens overnight. But we should harness it. We should take advantage. And I'd rather have I in California, the industry based here, than have it be based elsewhere, making money off of Californians. And so let's do it right. Let's try to let them innovate. Let's give them a sense that they have the ability to let their their talent roam and do good. But let's let them know it's got to be for the benefit of everybody, not just a few. And I believe that if we do this right, we can get the industry to understand that as they wish to have California be their home and be able to flourish, prosper here, that they have to make it so that others get to flourish and prosper with them. So energy, they're going to consume a ton of energy. Electricity needs. Water needs are great with these data centers. If they're going to locate here, and I would like them to locate here, they've got to help not just cover their energy expense, but maybe they can help us make sure we can expand our grid and our capacity for our clean energy electric electrification needs as well. And that way they're doing good for themselves by doing good for the state of California as well. So I look at I as a net, a very big net positive. But we do have to set the rules of the road. [58:35] Yeah. So let's hope that we end up with the best person to be governor first and foremost. Secondly, let's make sure that as Democrats, we put our best foot forward. Don't shame voters if they end up finding that the people that they vote for are not Democrats. That's I mean, 2020 4th November 2024 was a clear example of voters speaking their mind. And so let's not presume that we can tell voters what's good for them. Let's prove to voters what's out there and let them make the right call about what's good for the state of California and for them. And so I don't fear that we're in that danger. What I do fear is that people won't pay attention soon enough, and then voters will be rushing to make decisions based on less information than they should have had. That's what would concern me. But I have no doubt that we're going to be able to make some good decision. And I have no doubt that at the end of the day, that the candidates running to be governor in November, one on one, will include at least one Democrat, if not two, and that when I become governor, it will be because we had a good race [60:23] There are. [60:27] It's not easy because you're right. Federal tax dollars go straight to the Treasury. But someone has to collect them. Someone has to report them before the feds know what? we owe. And so, Yeah, that was very cryptically said, right. Look, [60:48] the first thing is we should not be in an antagonistic role with our federal government. We should not having to figure out how we can, skirt around the federal government. We should be working with our largest partner, the federal government. And the federal government should be working with its largest partner of the states, the state of California in. This is crazy, but we'll do what we have to do. And having served for 20 years on the, revenue generating committee, the Ways and Means Committee, I know taxes fairly well. I've had a right tax policy. So there are things we can do. None of it will be easy, but we're certainly not going to continue to feed the federal Treasury and not get our fair share back. And so we just have to make sure we're getting our fair share. I do believe this election in November will be very important, not just for the governor's office, but for our congressional delegation and what happens in the House and in the Senate. I know most of the, members in the California delegation, Republican and Democrat, and I know many of the leadership in the House and in the Senate from having served as the Secretary of HHS and having served in the Congress for 24 years. So I intend to make use of those relationships and those, established understandings of the workings of Congress to make sure that, as governor, I'm pushing for the people of California, this kind of relationship can't last. [62:23] For this federation of state to work, the federal government has to serve as the glue. It will not serve as the glue if it is clearly detached. It's, revenue sharing from the state of California. do something, So both and none of it will be easy, but we will do. Something [62:47] there are other states that are thinking this as well. Washington State, Oregon, Hawaii, and there are some great partnerships that can be had. I know that we've talked already, and I had some conversation with some folks in some of these states about doing something very similar when it comes to health care, when the federal government, the Trump administration, started to cut the funding for cancer research and other research at the National Institutes of Health, California started having conversation with other state about perhaps replicating what the NIH does so that our institutions and we've got some of the best institutions for, health care research can continue to move forward where the federal government is dropping the ball. We will figure out ways, and fortunately, we're one of the states that has capacity to do that. But at the end of the day, it's far better if we're working with our largest partner than antagonistic against them. [63:45] bet. Mr.. I love them at the same time. I work with them, just as I mentioned, I sued ice same time every day. I was working with Ice to do drug interdiction, sex, trafficking takedowns. So it doesn't mean you can't walk and chew gum. It just means that you have to be prepared to do both. And you're [64:15] U.S. needs. California more than California needs a US. And so what I'd say to you is that, California and there are places in Europe that would like to have California associated with them. There are places that would love to say, California, come join us. So I don't think that's an issue. And I don't think California needs to be broken up into five different states and so forth. What I'm saying is that California is a unique place, and it would be such a ill fated decision on the part of any federal leader to believe that it would be wise to undo that secret sauce that has California be part of the United States of America. Yeah, [65:06] We're going to defend our interest. You know, there are a lot of states that feel uncomfortable with this administration, a lot of states that believe that this administration would love to undermine the Republic and change the character of it, maybe undermine elections themselves. We have to be ready for whatever might come. But do I think that there are that many MAGA voters who really want to break up the United States? I don't think so. I think people wanted to shake up government, and a lot of people voted for Donald Trump because they saw that he was going to shake up government. Now that they're being shook, I think they're looking at a little bit differently because they don't think they think they were the ones that were going to be shaken. But we'll see, we'll see. [66:02] We're going to generate revenue. Certainly billionaires will pay more. But that initiative, if you're talking about the initiative called the billionaire tax, I don't think it's going to pass. I don't think it'll work because it's not tax policy. It's a one time, some people call it a confiscation. We'll call it. It's a one time tax on those who are considered billionaires. How do you, by the way, how do you know if you're a billionaire? Do you include all the artwork that you have? It's worth a lot of money or not. You could. The yacht that you have parked in the Mediterranean. How do you know about the Cayman Island accounts? How do you determine when someone reaches the threshold or gets below? It's just too complicated. But absolutely. The way I look at it this way, if someone in this state is making more money, a lot more money than a, a nurse, a teacher, a firefighter, a police officer, yet paying lower tax rates than those folks, then you're not paying your fair share. And I would say that you should be prepared that with me as governor, I will move the legislature to try to make sure that we have the revenue we need by making sure people pay their fair share. That, by implication, means that billionaires who pay at a tax rate lower than a teacher are going to pay more in taxes. But it's not a one time deal. It. We need to have a predictable revenue policy because otherwise otherwise we'll have a constant fluctuation. Major record for states, record surpluses and then record deficits. And this is it's a really choppy sea that we're on fiscally every year for the state of California in our budget. We can't how do you how does a business project, what the state will do when it's got budget deficits in budget surpluses, how do you know what the state will do when they try to take more money from me and my business? Will they be open for business when I need that regulatory help to get through the process? How do I know how they're going to work if they're so unstable? And so I think it's important to have real predictable path so that everyone around us, businesses, families, know what they can expect. And so that means having a tax code and revenue policy that gives us far more, a clear roadmap on where we will go, how much we can spend, what we can invest in and how we pay for things. And so a one time deal that may get caught up in the courts forever. I don't think it works. Stay tuned. I think there will be an initiative on the ballot that tries to really extend what we passed, about ten years ago, prop 55, prop 30, which was money dedicated to our schools. With so many going to health care, I think that's an initiative that should be, reauthorized by the voters. And so there are ways that we can get revenue that are more consistent, more predictable. And I would be supportive of that. But if you're paying at a tax rate lower than a teacher, firefighter and so forth, chances are you don't have to pay more