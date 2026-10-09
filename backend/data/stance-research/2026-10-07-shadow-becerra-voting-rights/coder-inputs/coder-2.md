You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-voting-rights/labels/coder-2.json. Write JSON only, matching
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

politician_id: 0f74219c-7d10-4d29-85fe-0f1d834df8a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Xavier Becerra — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: voting-rights
topic_id: d1792200-1d3b-4955-a0b7-0e6980d7a7b2  served_revision_id: 2a18c152-67a0-4380-a381-cb8795110a7c
Question: How should the government verify a voter's identity and eligibility?
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


## Sources

---
snapshot_id: f6e24ad6-a085-5a1e-ba13-a3cf267e5d24
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/ai/

Artificial Intelligence - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Artificial Intelligence California is where modern AI was built. The majority of the world’s leading AI companies are headquartered here, and this technology holds real promise to improve the lives of Californians: earlier disease detection, faster permitting, shorter lines at the DMV, and breakthroughs in medicine and science, once the stuff of imagination. That is the promise of progress, and California has always embraced progress. But California cannot accept technology moving so fast that a worker’s right to make a living and be treated with dignity is left behind, or that a child’s safety comes second to profit, or that the technology poses catastrophic risks to public safety. I am determined to channel this technology for human benefit, not as an engine of private wealth for the few, but as a force that lifts every Californian. If this technology transforms the economy as rapidly as many predict, the government must be ready to act: adjusting tax, spending, and regulatory priorities, and doing whatever it takes to keep people employed,economically secure, and safe. The gains of this moment will not be allowed to accrue only to those already at the top. I have taken on the most powerful industries in this state and won, and I will bring that same resolve to any entity that puts profit ahead of people in the age of AI. My approach is grounded in partnership with the technology sector, with workers, and with the communities whose lives this technology will shape. I believe responsible innovation and strong guardrails are not in tension, but in balance. California has shown that before, and we will show it again. With the federal government AWOL on the field — and that must change — California must set the standard. As Governor, I will work with labor, industry, safety experts, and impacted communities to get that done. California is a laboratory of innovation, and we should take pride in what the bright minds of this state have built. The question is never whether to innovate, it’s whether we have the leadership to make sure innovation works for everyone. I intend to answer that question and to make sure no Californian is left on the outside of this moment looking in. GUIDING PRINCIPLES Innovation That Works for Everyone. California built this technology, and California should benefit from it. AI should broaden opportunity, not concentrate it. My administration will pursue policies that help businesses grow, empower workers, and ensure the gains of this moment reach every community, not just the ones already at the top. Accountability First, With Industry at the Table. Through a process that includes industry input but is not captured by it, we will set firm guardrails around real harms, including threats to critical infrastructure, child safety, and harms that could emerge when AI accelerates dangerous capabilities or operates beyond human oversight. Workers Must Share in the Gains. The most valuable asset of our economy is our workers. They will be my priority. Technology should lift workers up, not leave them behind. Workforce investment and transition support are not barriers to progress; they are what make progress sustainable. A California That Brings Everyone Along. Opportunity requires access, and access requires partnership. My administration will work directly with the industry that built this technology to ensure every Californian, in every zip code, has the tools and knowledge to participate in this moment. POLICY AGENDA Expand AI Literacy for Every Californian AI literacy means understanding how AI functions, recognizing its benefits and risks, and using it safely and effectively, and right now that knowledge is not evenly distributed. My administration will work through California’s public schools, libraries, and community colleges to ensure every Californian, regardless of zip code or background, has the tools to participate in this moment. Community institutions are already serving as vital hubs for AI skills training, and my administration will resource and scale that work in partnership with industry, so the communities historically left behind by technological change are at the front of the line this time. Leverage AI to Tackle California’s Most Intractable Problems California faces challenges that have resisted decades of conventional policy: homelessness, housing affordability, climate adaptation, and a health care system that reaches some communities far better than others. My administration will actively partner with the technology sector and research institutions to direct AI toward these problems, deploying it inside state government to cut permitting delays, improve benefits delivery, and find efficiencies that have long eluded us, while ensuring every deployment is transparent, audited, and developed alongside the workers it affects. Responsible AI in State Government AI has real potential to improve how California delivers services: faster permitting, earlier detection of public health risks, and more accessible benefits navigation. My administration will pursue that potential with full transparency and rigorous evaluation. Every California civil servant whose role is affected by automation should have a voice before that decision to deploy is made, not after. And every AI system deployed by a state agency will be subject to an independent audit. Track and Respond to AI’s Economic Impact Automation is already eliminating jobs in measurable numbers, and the advances of artificial intelligence are accelerating both the pace and the scope of that change. The state’s existing labor market infrastructure will be directed to continuously track AI’s effects on wages, employment, and sector-level displacement, with findings feeding directly into workforce investment decisions and, where the data demands it, broader policy intervention to ensure that workers come first and the gains of this technology are broadly shared with all Californians. Workforce Investment and Transition Support Displacement without support is abandonment. I will work with the Legislature, the California public education system and industry partners to build accessible, stackable workforce programs that prepare Californians for the AI economy and support workers navigating role changes. The goal is a skilled workforce that benefits employers and workers alike, with real, reachable transition support, not plans that exist only on paper. Fund CalCompute Startups, researchers, and public institutions should not be locked out of frontier AI infrastructure. I will fund CalCompute fully and make it operational, ensuring it delivers on its promise of broad, equitable access to AI infrastructure. Data Centers, Clean Energy, and Ratepayer Protection California’s electric ratepayers must come out winners from the growth of advanced computing infrastructure. I will pursue an economic-forward standard: data centers that operate in California add value to our current energy infrastructure, are powered with clean energy, cover the costs of their own energy needs, and meet environmental performance disclosure requirements. In return, my administration will improve data center permitting programs and provide the policy certainty industry needs to invest and grow in California and the technological opportunities of tomorrow. Enforce & Strengthen California’s AI Standards California has the nation’s strongest AI safety laws. I will ensure existing requirements are actively enforced, close the gaps that allow bad actors to evade accountability, and work closely with technologists, workers, industry and communities to review, track and strengthen standards as the technology evolves. Good rules mean nothing without monitoring and enforcement. Protect Children and Families Child safety and well-being must be foremost in the formulation of California’s AI policy. AI products accessible to children carry real risks: content promoting self-harm and suicide, manipulative design that exploits adolescent psychology, and AI-generated personas presented as real. I will direct the full resources of my Administration and use its platform to hold accountable any company willing to put profits ahead of children’s safety. Transparency in Automated Decision-Making Workers and consumers deserve to know when consequential decisions about them are shaped by algorithms, and to have meaningful recourse. My administration will pursue transparency and human review standards for high-stakes automated decisions that significantly affect a person’s livelihood, health, housing, or freedoms that are clear, proportionate, and workable. Build a National Framework The Trump administration has abdicated federal responsibility on AI governance, leaving a patchwork of state laws, or no laws at all. This ultimately protects no one. A national framework is essential, and California cannot wait for Washington to act. I will work across party lines to push states – red and blue – to adopt California standards and create a national framework. Strong standards and a thriving AI sector don’t have to be in conflict, and California is fully capable of setting the gold standard. Up Next Homelessness Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: bb11e9cc-c258-52b3-9725-8f10caecac80
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/health-care/

Health Care - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Priorities Health Care Healthcare has been the throughline of my entire career in public service. I started as a legal advocate for people with mental illness who had no voice. I served twelve terms in Congress and on the Ways and Means Subcommittee on Health, fighting for every family to have the same assurance of care that my family had growing up. As California’s Attorney General, I won a $575 million antitrust settlement against one of the largest health systems in the state, cracked down on pharmaceutical “pay-for-delay” schemes that kept generic drugs off the market, prosecuted Medi-Cal fraud, and led the three-year federal court fight that saved the Affordable Care Act for 133 million Americans with pre-existing conditions. As HHS Secretary, I negotiated drug price reductions of up to 79% on some of the most widely used medications in America, the first time the federal government had ever directly bargained with pharmaceutical companies on behalf of patients. Bringing costs down is not an aspiration for me. It is a record. Now Washington is working to undo all of it. The Trump administration is targeting Medi-Cal, gutting the ACA, and abandoning the drug pricing reforms that were just beginning to deliver savings for families. With the federal government absent from this fight, California must be the firewall. I sued the Trump administration more than 120times as Attorney General and won, and I am ready to do it again. But fighting Washington is not enough. The next governor must do more than play defense. We need to protect coverage for every Californian today while building toward a system where universal access is not a promise deferred but a guarantee delivered. The most effective way to lower healthcare costs is to keep people healthy in the first place. A family without a primary care doctor does not simply go without care. They end up in an emergency room, at far greater cost to the system and far greater harm to themselves. Primary care is the only part of the healthcare system where investment consistently produces longer lives, greater equity, and lower overall spending. As Governor, I will move California toward a system that does not just treat illness but prevents it, with community-based care, robust screening, and the kind of coordination that reaches the people who need it most. None of this works without the people to deliver it. California cannot build toward universal coverage without the providers, nurses, and caregivers to make it real. We face serious shortages in primary care, behavioral health, and rural medicine, and those shortages fall hardest on the communities already carrying the heaviest health burden. I will invest in growing and retaining a healthcare workforce that reflects the full diversity of California and reaches every zip code, because coverage without access is not coverage at all. Guiding Principles Bring Healthcare Costs Down for All Californians. Lower the financial burden Californians face when accessing care, from premiums and out-of-pocket costs to prescription drug prices, using every tool of state purchasing power, regulation, and enforcement available. Guarantee Access and Build Toward Universal Coverage. Protect existing coverage from federal rollbacks and chart a clear path to ensuring that no Californian is left without care, regardless of income, zip code or immigration status. Increase Investment in Primary Care. Make prevention and early intervention the foundation of the system. It costs the state far less to give a family access to a doctor than to wait until a preventable condition lands them in the emergency room. Build, Support, and Invest in a Stronger Healthcare Workforce. Grow and retain the providers, caregivers, and allied health professionals California needs, especially in rural communities, safety-net settings, and underserved specialties, so that coverage always comes with adequate networks and actual access to care. Policy Agenda 1. Protect Healthcare and Keep Hospitals, Clinics, and Medical Practices Open On Day One, I will issue an executive order directing state agencies to maintain coverage continuity for every Californian affected by federal cuts or Medi-Cal rollbacks. I will also direct state agencies to protect access to essential, medically appropriate health services from federal restrictions, including reproductive care and healthcare for immigrant communities, and ensure uninterrupted, equitable access to contraception, abortion, and maternal health support. I will immediately assess which rural hospitals, community clinics, and safety-net providers are most at risk and execute emergency state interventions to prevent cascading closures. And I will fight to fully implement Proposition 35, which California voters passed in November 2024 to dedicate MCO tax revenue exclusively to Medi-Cal, ensuring those funds go to stronger provider payments and expanded access to care, not federal clawbacks. State interventions will ensure that public dollars come with public obligations, including maintaining fair labor standards and respecting the representation rights of the healthcare workforce. 2. Cut Prescription Drug Costs Using State Purchasing Power I negotiated drug price reductions of up to 79% as HHS Secretary, finalizing historic deals on ten high-cost medications including Eliquis, Jardiance, and Xarelto that will save Medicare billions of dollars every year. When I am Governor, California’s full purchasing power goes to work for patients on Day One. I will negotiate maximum reimbursement rates for drugs purchased through state employee health plans, Medi-Cal, and all state-administered programs, and direct agencies to prioritize lower-cost biosimilars and therapeutic alternatives wherever clinically appropriate. 3. Expand CalRx and Build Western States Drug Independence California pioneered CalRx to produce and purchase essential medications at lower cost, and I will accelerate and expand it, moving urgently on high-impact medicines like insulin, inhalers, EpiPens, naloxone, and antibiotics. I will also forge joint purchasing arrangements with other Western states to maximize our collective buying power and build regional pharmaceutical independence, so that a hostile federal administration or a supply chain disruption can never hold California’s patients hostage. 4. Streamline Administrative Oversight to Reduce Waste and Improve Efficiency Too much of what California spends on healthcare goes to paperwork, not patients. I will issue a directive requiring all healthcare oversight agencies to identify and eliminate duplicative requirements that add cost without improving care, produce a unified plan to modernize and consolidate oversight activities, and partner with health plans and providers to review outdated facility standards and operational rules that drive up costs and restrict innovation. Every dollar freed from administrative waste is a dollar that can go toward expanding access. 5. Launch “California Connected Care”: Universal Telehealth Access As HHS Secretary, I oversaw the historic expansion of telehealth during the pandemic and saw firsthand how it saved lives in communities that had never had adequate access to specialists. As Governor, I will issue an executive order requiring all state-regulated payors to reimburse telehealth visits to the fullest extent permitted under law, prioritizing telehealth delivered by California-licensed health care professionals through local and regional providers to provide urgent care for conditions that do not require an in-person visit, and leverage California’s volunteer physician registry to open specialty telehealth access to communities that have never had it. I will also direct our oversight agencies to launch oversight and integrity programs to match the expansion of telehealth services. When a patient with a chronic condition connects online, they will be linked directly to a Federally Qualified Health Center for ongoing care. 6. Launch the “California Prevention First” Initiative The most effective way to lower healthcare costs is to keep people healthy in the first place. I will invest in comprehensive community-based prevention programs targeting the chronic diseases that drive the highest costs, including diabetes, hypertension, cancer, substance use, and more, with community health workers, robust screening programs, and doula care. This initiative will prioritize Medi-Cal populations and disadvantaged communities that bear a disproportionate burden of chronic illness, and will invest in modern data systems that track patient needs and close gaps in care so that prevention is measurable, not just aspirational. As Governor, I will also strengthen public health infrastructure by restoring trust in science and expanding access to safe, effective vaccines, as I recognize immunization as one of the most powerful tools to prevent disease and protect public health. Building on California’s world-leading research institutions and innovation ecosystem, my administration will recommit to fact-based decision-making and double down on science and research to guide policy, improve outcomes, and prepare for emerging public health challenges. 7. Launch the California Healthcare Workforce Investment Fund Coverage without providers is an empty promise. I will establish a long-term dedicated fund to grow the healthcare workforce where it is needed most, offering loan repayment and forgiveness programs, housing assistance in high-cost areas, and targeted incentives for primary care, behavioral health, women’s care, rural medicine, and dental providers. The fund will build lasting partnerships between health systems and California’s community colleges and universities to train the next generation of nurses, medical assistants, physicians, dentists, and allied health professionals, with incentives for health systems that invest in the workforce pipeline. I will also hold health plans accountable for building and maintaining adequate provider networks so patients can access timely, high-quality care when and where they need it. 8. Center Affordability in Every Decision Universal coverage, timely access, and a strong safety net must translate into real savings for real families. I will work with regulatory agencies to ensure that as waste and inefficiency are eliminated, the savings flow back to patients, not to shareholders. I will work with employers and other purchasers of care to drive down premiums and out-of-pocket costs across the board. The goal is a system where doing the right thing for patients is also the most financially sustainable path for providers, plans, and the state. 9. Stop Paying Twice for People Who Never Lost Eligibility California loses hundreds of millions of dollars every year processing the same Medi-Cal cases twice, when eligible enrollees are dropped due to paperwork errors and then re-enroll weeks later. Children’s churn cases alone cost $120 million every three years. I will modernize Medi-Cal’s eligibility infrastructure with automated renewals that verify eligibility through existing state data, consolidate the fragmented county-by-county enrollment system, and ensure that a missed letter or a data entry error never becomes the reason an eligible Californian loses coverage. 10. Crack Down on Waste, Fraud, and Abuse I prosecuted Medi-Cal fraud as California’s Attorney General, and California is still losing billions to fraudulent claims and misused benefits. I will create a dedicated healthcare fraud task force with the authority to hold funds, investigate bad actors, file charges, and see cases through to verdict. Services that are overutilized or delivered through the wrong system, including transportation and hospice abuse, home asthma remediation, and housing benefits that belong in social services will be reined in. Every dollar recovered is a dollar that can go to care for the patients who need it most. 11. Stop Large Employers From Shifting Costs onto Taxpayers Some of California’s largest and most profitable corporations pay wages so low that their workers qualify for taxpayer-funded Medi-Cal, effectively subsidizing their labor costs with public money while disadvantaging competitors who do the right thing. This year’s state budget laid the foundation for this fight through the Fair Share from Big Corporations Act, directing the Department of Finance to bring forward options by March 2027 — and if I have the honor of serving as Governor, I would look forward to working with the Legislature to turn that groundwork into a real, enforceable policy. I will pursue a fee on large employers who do not offer health coverage to their low-wage workers who qualify for Medi-Cal, so that corporations who shift their healthcare costs onto taxpayers pay their fair share. Profitable companies should not get to pass their obligations onto working families. 12. Modernize and Consolidate Medi-Cal Financing to Ensure Long-Term Stability Medi-Cal’s current funding structure is a patchwork of supplemental payments, time-limited tools, and fragmented streams that obscures true costs, limits transparency, and makes long-term planning nearly impossible. I will pursue a unified financing strategy that consolidates duplicative payment structures, strengthens base rates, and ties funding to clear performance and accountability standards, so that Medi-Cal dollars go to access and quality, providers can plan with confidence, and California is no longer vulnerable to federal disruption of the mechanisms we rely on most. Up Next Fighting Donald Trump Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 00022e11-ea69-5628-8244-b254cc20fa75
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [0:26] Absolutely, he's wrong. Uh, what he would do is he would damage our state even further, make it harder for working families. He'd make it tough for folks like my parents who came to this country with, uh, with $12 and they settled in California. They were able to build the California dream, but they had to work hard. They needed to make sure that the government was, was there with them. If you start cutting taxes and Steve Hilton's plan actually goes beyond just, uh, the 150 ,000, he claims he'll try to cut. He wants to give the richest Californians, millionaires and billionaires, a 40 % tax cut. Which means, of course, he'll take it out of our schools, he'll take it out of healthcare, he'll take it out of housing and make the conditions even worse. We have to have sound policy, whether it's tax policy or spending policy, to make sure that we can bring our California dream back to life. Right now, we have a situation where if you start making tax breaks for the wealthiest, you damage our working families like my parents. Mr. Helton? [2:03] Again you're gonna hear a lot of stories a lot of new math a lot of alternative facts from Steve Hilton the math doesn't add up what he's talking about he's gonna have to take it out of somewhere it will come out of our schools 50 close to 40 % of our budget in California is for our schools and so Steve Hilton is talking about making taxes not just 150 ,000 but he's got a plan to give the wealthiest Californians a 40 % tax cut. [2:47] What I said is that you shouldn't [2:50] give the tax breaks to the folks who are making the most money in California. That's your plan. If you look at your plan, you're going to make across -the -board tax cuts. You're going to end up giving the wealthiest Californians, billionaires, a 40 % tax break, the biggest in California history. You only talk about the portion of about 150 ,000, but there's another aspect to it. You don't like to talk about that. No, I do. I'll tell you, I'm very [3:56] with Javier. What I wouldn't do, Steve, is try to convince the people of California that proposing Trump tax policies, promising Trump tax cuts, believing you're gonna get better results than Trump has gotten so far to date, That that is what isn't it the definition of insanity you do the same thing over and over again expecting different results Yes, you're using Trump's like voting Democrat promises you expect different results You're gonna end up with Trump results If you follow Steve Hilton's plans [6:36] We will the housing gap, I've said already that we have to at least double the rate of building of homes. How much can we do? It just depends. How much red tape can we cut? How fast can we try to expand down payment assistant programs? How fast can we make sure Wall Street isn't outbidding the teacher or the firefighter for a home in California? We have to make sure we don't let Wall Street investors buy homes over those people who are working hard in California. And the final thing I'll do is what I did when I was AG. I will enforce the law that requires local governments to build. Mr. Holman? [7:35] that if you like. You did nothing. [7:46] sued [7:47] the [7:47] of Huntington Beach, Steve. That's more red tape, not less. No, no. It's enforcing the law because Huntington Beach was not following state law which required it to encourage building in its community and so they were not following the law as attorney general i enforced the law and guess what we won because huntington beach was denying permits and we have to build and no locality should have the right to try to stop all of our people in california from having the housing they need even [11:00] If you listen closely, you can hear Donald Trump in that response by Steve Hilton. He's not interested in regulating AI. He's not interested in telling these companies, you have to protect not just our kids and not just in school, you have to protect our workers who are looking at the prospect of losing their jobs to AI. You're looking at public safety that may be in danger by having AI penetrate our privacy. You know, it's really interesting. The president got a pinky promise in this forum that he had with AI leaders. That's all he got. No comment. He could go ahead and start an illegal war in Iran. He could go ahead and tear down East Wing or the White House, but he can only get a pinky promise from the largest leaders of AI. That's not what we need. And Steve, it's not a gimmick to ask for guardrails. It's the real thing. You use the word gimmick. It's not a gimmick. We need real enforcement. [12:01] The reason you could trust me, Steve, is because I... How [12:07] You want to answer? The answer is the reason you could trust me is because I have sued Meta, I have sued Amazon, I have sued Google. I have sued these very companies. I have enforced the law against these companies, and I will continue to do so as governor. The difference between us, Steve, is I have a record of having done that. You just say the talk, but [13:02] First, let me correct the record. I have helped create millions of jobs during my service as a member of Congress in preserving the protection for the state of California when I was attorney general, when Trump was attacking us. And as Secretary of Health and Human Services, I expanded healthcare to more Americans, which required more doctors, more hospitals. So unlike what you've just said, Steve, the facts show that I've helped create jobs. But to your point, since when do I have to respond to politicians? I'm running for governor of California. I'm looking for the vote of California voters, not some politician in Washington, D .C. [13:56] Yeah, of course. And I would work with our local communities to make sure that we enforce. This, Dana, the standard I think is pretty straightforward. Having a data center, does that benefit the community they want to locate. If it doesn't benefit them, if they don't see it as an investment in their community, if all you're going to do is rob their energy and electricity and their water, that's not a good deal and we should say no. But if someone wants to come in and build a data center that creates more jobs in the community, adds more energy to our grid, and it actually protects and adds more water capacity, then let's talk. But it has to be good for the community. We can do that, but if you're Donald Trump and his endorsed candidate, you probably want to lay these guys and let them do whatever they want. [15:14] Maybe the difference here, Steve, is that I've gotten the endorsement of our law enforcement peace officers throughout the state of California because they think I'm gonna help public safety. I've gotten the support of carpenters and construction workers. I was a member of the construction field as well for a while before I got to become a lawyer. But what I'm saying to you is this, people who know my policies are supporting me because they think it'll be good for them in their communities creating jobs but pinky promises Steve is that all you can do is that all your your endorser Donald Trump can do to make sure AI safety reaches our communities a pinky promise [16:29] our peace officers and our carpenters and our teachers know that you think it's their fault that we haven't gotten control of these things. [18:44] Steve, you're running for governor of California and you'll enforce Trump's laws at the federal level, but you won't enforce state laws at our level. California welcomed you into California and you welcomed ICE mercenaries into our state in return. How does that, how do you square that? You know, you're an immigrant. I have fought all my life to make life better for immigrants, to represent them well, to defend them, to let them grow and build like my parents. But here's the problem I have with your policies. You seem to welcome immigrants who look like you but deport immigrants who look like me. We need to have a governor who will protect everyone who works hard. I don't need to stand here and listen to you say that you'll enforce Trump's laws but you won't enforce California state laws. [19:45] farm worker in California why only farm workers that's what you [20:27] Trump, Trump, because he is your supporter. You chased his endorsement. [20:32] you just said it too and your policy say it every day. Because you've got nothing to offer Californians except more of the same. Let's use your words. You said Trump's ICE [20:43] immigration policies in his raids were, your words, perfect. You said that every farm worker in California should be deported. Your words. That's simply not true. Those are your words, Steve. [21:07] Do you deny that you said that Trump's immigration raids are perfect? [21:11] All that he's got are these insults. Here's your chance to deny that you said Trump's [21:39] It is good to have a regulated system of immigrants to come into our country, including California. And that's something that I have always pushed for. It is bad when immigrants are being separated from their children. It's bad when immigrants are being killed indiscriminately. It's bad when US citizens are dying through these immigration raids. So let's have regulation of our borders. We have a right as a sovereign nation to do so. I have always been for that. I am not for violating the constitution. I am not for treating immigrants like animals. And I am for recognizing that immigrants lift up our state. They build it every day. And I say that as the son of immigrants, that what we should do is have an immigration reform that will allow us to decide who stays and who goes. But Steve thinks it's perfect to let ICE mercenaries come on into California. And he welcomes it, even though our state laws require that ICE follow federal immigration law. Helm. [23:43] those Retread Trump talking point with the New York Times that Trump and they want to pull it surprise 24 You've used those. [23:53] In fact, every candidate... It was your Democrat colleague, Antonio Gutierrez. Let's let Secretary [24:00] We could follow the rules, Steve. Let me answer the question. Trump left a system for care of these immigrant kids that had been dismantled. Because he doesn't want them here. He made it very clear. Remember, he used to put kids in cages. He used to separate those children from their parents. We changed all that. I am proud of the record and all my life of working on immigration and in protecting immigrant children. What I won't do is do what you've done and welcome ICE raids so they can come and separate kids from their parents that can kill people indiscriminately. I will not be part of that and the record speaks for itself, Steve. You tried this before, it didn't work. You're gonna try it again because you have nothing else. Those aren't the facts, but you can peddle them if you'd like. [24:46] Mr. Helm. [25:22] that's what messing with [25:23] so once again these [25:27] misrepresentations that he's made of fact made of facts the the New York Times story didn't even go into those details about 480 someone the number keeps changing you said it was one one day, now it's another thing. Look, you could continue to do that. The fact remains, Donald Trump has a history of trying to deny immigrants their rights, abusing them, and he did that with kids. We changed that. I'm proud of the record we have when it came to providing care to these kids. What I will tell you is this, we need to fix a broken immigration system because no child should have to spend time in a detention center when they're three or four years of age. [27:43] Well let me unwrap this a bit here. Steve Hilton wants to put polluters in charge of our fossil fuels, of our move towards greener energy. He wants to let the industries decide at what pace and where and how do it. He wants to let Donald Trump take oil leases out of our coast, on our coast. He wants to, he said it himself, drill baby drill. He wants to drill baby drill along the coast of California. Steve, you weren't living here in California at the time, you weren't living in America at the time. We went through that experience. We don't want to see our coastline damaged. And talking about firefighters, Steve, your policy that gives that 40 ,000, 40 % tax cut to the wealthiest, you're going to cut firefighters from fighting [28:29] wildfires. [28:57] $2 more than it was when Donald Trump started the war in Iran. Just tell them [29:01] number. [29:02] It's over $6 a gallon. The national average. [29:05] The national average is over $4 a gallon. What is it exactly? Do you know? It is over... You can't give an exact number because... [29:14] Yeah. And so what I would tell you is this, Steve, more when it comes to diesel if you didn't have Trump's policies on the Iran War. Gentlemen, I'm... That's caused major pain for folks, but if I can answer on this wildfire issue, [29:28] Steve, you just called firefighters bureaucrats, these are the folks that are on the front line fighting fires and you're saying we should go ahead and get rid of them, cut them because they're bureaucrats. No, I'm saying we should call them bureaucrats [30:22] because as attorney general I demanded accountability and I will make sure that as governor I will demand accountability of our local governments who have control of the streets in their cities and in their counties what we will do is we will make sure the encampments are cleared we will make sure that we are enforcing the law because we have a right to make sure that those encampments are cleared we're gonna make sure that we tackle what is one of the major issues that it's involved with these folks who or staying in the streets. Mental health and substance use addiction. We have to be serious about tackling that. And the thing I'll do most because it's so important to work with the cities and the counties to tackle the streets and remove people from the streets and find them shelter. But as a state leader, I can make sure that we're providing the investments it takes to make sure any California who may be by some medical emergency or unexpected loss of a job is now on the verge of losing their home. I want to help them because it's easier to help you stay in your home than pulling you off the streets and trying to get you upright again. It costs way more to let them get on the streets. [32:08] And I guess Steve, you give Donald Trump an A for having denied our local governments the funding they need to tackle the homelessness crisis. Donald Trump has this habit of holding dollars from the state of California. Californians pay more in taxes to the federal treasury than any other state. Yet Donald Trump keeps holding our money back. He's holding money back for homelessness. He's holding 30 billion dollars hostage for the victims and survivors of the Altadena and Pacific Palisades fires because he wants his way on voting. He wants to restrict voting so he won't give that money up until we change our laws. [32:45] That chance, we're gonna fight to get our 30 billion for our victims and our survivors and we're gonna keep our people voting. [33:20] You've got to correct the record. Steve Hilton is saying that the $30 billion is being held up by the state. What about the $2 .5 billion that Gavin Newsom... I said $30 billion. You just said that in the state. Jake, let's clarify this because there are families here in LA who are still waiting for their assistance. From Gavin Newsom? and 30 billion dollars talk to any member of Congress, Republican or Democrat, 30 billion is waiting to go to Pacific Palisades and Altadena. Donald Trump doesn't wanna let it go because Donald Trump isn't getting his way on elections. [34:18] I'm going to vote no. I said that very clearly from the very beginning. Not because I don't agree with so many Californians who think that billionaires haven't paid their fair share because they haven't. It's that this is not the way to do tax policy. I'm the only one on the stage who's done tax policy. I'm the for working families I did it for making construction of affordable housing more easier to do I've done it for families with children I've given tax cuts I've also had to deal with raising revenue and what you don't do is you don't have a policy where it's a one -time tax and it isn't predictable and sustainable we need to have policy that everyone sees is fair it will sustain us going forward because we need to pay for our schools we need to pay for health care we need to pay for housing and we have to make it so that everyone is willing to do it. But no doubt, billionaires in California, too many of them are not paying their fair share. When you can pay a tax rate lower than a teacher, a firefighter, a nurse, you're not paying your fair share. [37:36] Thank you, sir secretary Sarah, I love these stories Steve you spin them all the time I guess it's from your experience being a talking head on Fox News You're so good at that even though they're not factual even they have nothing to do with reality Did Karen Bassett say that? Can we make sure that we don't get interrupted when we try to give responses? That was part of the rule, Steve. It would be helpful if you stopped interrupting. And I hope that's not gonna count against my time. Well, keep going, sir. Okay, so [38:03] Prop 39 is on the ballot. Prop 39 is an initiative that is backed by Donald Trump. He couldn't get his save act out of Congress, which tries to interfere in elections, so he's gone around the country and put initiatives on the ballot. In California, it's Prop 39. Steve Hilton is supporting the Trump back prop 39 that would make it hard for California's to vote We have to all vote no on 39 to send a clear message to Donald Trump and Steve Hilton that we want people to vote We don't want to make it tougher for them to vote mr. [41:23] You said I learned a lot today. Same here. [46:15] Dana, we had nearly eradicated measles. When I left HHS, you rarely heard of a case of measles. You rarely heard of a case of someone dying of measles. Today, children are dying of measles. Today, the spread of measles has reached a proportion we haven't seen since the 1960s, I believe. That's what happens when vaccine deniers take over. And this is what'll happen to California if you let someone who is willing to promote that type of attitude become governor of the state of California. We can't reward those who are willing to let families die. We know vaccines work. And we should continue to enforce, make it possible for us to have the vaccines available. Actually, I have to mention real quickly that one thing that Steve said is absolutely untrue. [47:03] We never forced anyone to get a vaccine. We don't have the power to do that at HHS, Steve. If you knew the law, you would recognize that. The states have the authority to decide who gets vaccinated in their states. Thank you, sir. Mr. [47:14] Did you give [47:26] Falsely. We didn't suggest that. The medical professionals who helped develop the vaccine And then he spoke out against it. Are the ones that decided what we should do with the vaccines, including for children. We never made a vaccine available for a child until the medical professionals and the science community said it was safe. You should know that because your friend, Donald Trump's HHS, oversees those agencies that make those decisions with working with the states. [48:25] We followed the science. This is the problem when you have politicians dictating what we should do in healthcare. When you have politicians telling the medical experts what we should do like on vaccines. We stayed away from trying to force anyone to do anything especially if it didn't follow the medical science. You are willing to let Donald Trump force people to follow your dictates. It's just like with a woman's right to choose whether she should have an abortion. You wanna be able to dictate whether or not a woman should be able to have an abortion. Let's stay with the [50:22] This is what happens when you get to use your own facts, these alternative facts that don't relate to the actual situation at hand. I won't get into it because I don't have enough time, but what I will tell you is this. In rural California, we're going to have hospitals closed. We're going to have community health centers closed. Doctors won't be able to provide services because of Donald Trump's cuts to pay for tax breaks for billionaires and large corporations. that trillion -dollar cut to health care, we're gonna make sure we don't kick people off of health care because it's not what you should do for families who need health care, and it's not what you should do to those providers, those doctors and those hospitals and those clinics that are willing to stay open, but they need to get paid. [51:12] So if he's gonna let me answer the question, I will answer it, because when I was secretary of healthy human services, we had a state, Georgia, that did have work requirements. And what we found was that the way Georgia was implementing those work requirements, it was kicking people off of Medicaid unjustly who did qualify for it. And so if you're gonna make these requirements that make people jump these hurdles when they do qualify for medical benefits, then you better make sure you do it right. And so this is gonna be a requirement that I as governor will have to work with and I will make it work because I'm not gonna kick people off of the health care rules. [52:28] Jake, first, we've lost some 50 ,000 jobs in Los Angeles and California from the film and movie industry. these are middle -class jobs. I'm not talking about the high -paid actors. I'm talking about the grips, the camera people, the people who build the sets. They make a decent living. Those jobs have left. We've got a fight to keep Hollywood in Hollywood and I've said I'll do everything I can to make sure that happens. Here's the rule. Pretty simple. If we give a tax credit, so long as we get more than one dollar back for that dollar in tax credit, we're to do it because Hollywood belongs here. We don't want it to be in Sydney, Australia. It shouldn't be Sydney wood. It shouldn't be in Toronto, Canada, not Toronto wood. It needs to be Hollywood and we'll fight to keep Hollywood business in Hollywood and in California. [54:10] First, he says that I have done nothing on Hollywood. I was in Congress, I was part of the team that enacted the first federal tax credit for film and movie production. So Steve, I was there 20 years ago when you weren't even in California. Secondly, when it comes to this water issue, quit using false statements. I won that case in court on water, not because I was trying to protect little fish. It's because Donald Trump was trying to impose his standards on California when it comes to water infrastructure. We have a right to make sure water in California is regulated by California. I sued and [55:11] We don't see our education system well coordinated. It is not working well. There's too much compliance required. What we have to do is make sure before we pass a child on, we're making sure that they are at grade level. we have to provide the tutoring that they need, we have to start earlier, we've started transitional kindergarten which gets a four -year -old into our schools, but too often when they're one, two, and three years of age, they're not being ready, prepared to get into our school system. So I would fight to make sure that we're working with our teachers because they're the most important people that will make sure their success for this child. I'll make sure that every public dollar, taxpayer dollar that we put in our schools and nine out of 10 kids in California go to public schools, that those taxpayer dollars stay in our public schools. Steve Hilton wants to send those public taxpayer dollars to private for -profit schools, not on my watch. We wanna make sure we let community schools thrive. Steve Hilton would kill those community schools by taking the money out of those communities and sending it to private for -profit institutions. We're not doing that. [57:01] Secretary Becerra? Well, he attacks teachers. He's made that very clear. He doesn't like teachers. I believe that the people who are supposed to train our kids should be treated like professionals. They are underpaid compared to professionals with similar education levels. He attacks them. He says they're doing the wrong thing for our kids. These are the people we put our children's futures in. We should treat them like real professionals and reward them like real professionals. That's what I'll do. Mr. Pelton.

---
snapshot_id: ce2ff217-a1e1-54c5-9ac3-8c739a7049db
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/protecting-our-families-communities-from-the-next-wildfire-disaster/

Protecting our Families & Communities from the Next Wildfire Disaster - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Build More, Build Faster Protecting our Families & Communities from the Next Wildfire Disaster Too many families across California know what it means to lose everything in a wildfire. We need a plan as big as the problem: make our homes fire-safe, provide residents with the best possible information as fast as possible in an emergency, and back our firefighters. How it works We’re going to do everything we can to rebuild, protect, and prepare for the next fire. Build More, Build Faster As Governor, I’ll sign an executive order declaring a housing emergency, cutting red tape so we can build back our communities even faster. Fire-Safe, Fire-Ready Communities Initiative: Affordable Community Fire-Proofing The more homes we can fireproof in risky areas, the safer our communities will be. That’s where my Fire-Safe, Fire-Ready Homes Initiative comes in to make community hardening more affordable. We’re going to create the first statewide plan that identifies community wildfire risk and the most cost-effective ways to reduce it. I’ll use our state resources and provide direct support to Californians, especially our lowest-income families, so fireproofing is accessible to all homeowners. Alerts That Work Initiative When disaster strikes, our response is a matter of life and death. We’ll create one standard across California. Staff on call 24/7, with trained backups. Alerts out within minutes. Messages written in advance, in the languages Californians speak, with clear instructions and accessible to people with disabilities. Delivery through every channel — cell networks, sirens, loudspeakers, patrol cars, door-to-door — so no one is missed for lack of a phone or internet. And a debrief after every fire so each response is faster than the last. Backing our Firefighters As Governor, I’m going to support our firefighters with the resources they need and the workweek they deserve. Supporting firefighters means investing in the people who stand ready to protect Californians when we need them most, improving our firefighter retention rate, ensuring better pay and making safety a top priority. How you’ll benefit Making your home and your community fire-safe costs money, and no family should have to choose between putting food on the table and protecting their home. We’re going to invest in a permanent source of funding to help homeowners meet the state’s home safety standards – including direct financial help for families who need it most. As Governor, I’ll make fire safety for homes and our communities affordable – and as we cut fire risk, we bring down your insurance bills. We’re going to make homes fire-safe, fire-ready and protect families and communities before a fire ever starts. But we’ll be ready when one breaks out anyway. Why it’s good for California, too Fourteen of the twenty most destructive wildfires in California occurred in the last decade including the Eaton, Palisades, Camp and Woolsey fires. These fires underscore the need to take action to protect people and our communities. There are two million homes in our highest-risk areas, 90% of them built before modern, wildfire-safe building codes and community design. The Alert That Works initiative will update our communities’ response times, we’ll cut red tape, and we’ll support a strategy that hardens our homes, clears hazardous fuels, and fully backs our frontline fire personnel. What’s standing in the way Californians deserve action not just from the state, but from the federal government. Donald Trump promised to “end the nightmare of delay,” yet more than 18 months later, families in Altadena and Pacific Palisades are still waiting. Donald Trump is sitting on over $30 billion in aid while families are forced to rebuild out of pocket. Americans are being denied help for one reason: they live in a blue state. He’s demanded we reopen non-existent water spigots. He’s used disaster aid as leverage to change our voter ID laws and rig our elections. His actions are those of a crooked dictator, not a President who cares for the American people. As Governor, I won’t stop fighting until Donald Trump releases the aid that thousands of Californians are owed. Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 23bb42cf-0a19-510a-8c81-ab5bca307b44
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [5:15] thank you my parents came to California with $12 in their pocket they worked really hard they never had a chance to go to college but they gave my three sisters and I that very opportunity and as a result we got to live the California dream but too many families today don't believe that the California exists today for them that's why I've been fighting all my public life to make sure that people get to experience what a construction worker and a clerical worker without a college degree had a chance to do that's why I fought to protect the Affordable Care Act when Donald Trump tried to eliminate it the first time he was president and I took him all the way to the Supreme Court and we beat him that's why I had to go at him toe -to -toe over and over more than 120 times when I was attorney general and we beat him whether it was saving the DACA program or whether it was making sure that we protected our families against ICE we fought and we won we're gonna do the same thing again because today it's housing it's health care people want a fighter people want someone with experience I hope to gain your vote [20:10] right in the same way I did it when I was attorney general we establish a bureau that dealt with medical fraud working with the federal government unfortunately Trump is a problem because Trump took a trillion dollars out of the health care system out of the Medicare or them excuse me the Medicaid and the medical system Trump is now trying to deprive California of another billion dollars in health care for medical he doesn't have the right to that you still have to prove that there's been fraud and abuse he is in advance taking money even though he hasn't proven in court what he's done so we should go after him the way I had to do over a hundred and twenty times when I was attorney general we will fight to get those tax subsidies under the Affordable Care Act back for California families we will fight to make sure we get the money that we sent to the federal treasury for medical in California because otherwise three million Californians are in jeopardy of losing their health care we won't let Trump get in our way and whether it's the Trump gas tax because he's recreates a fight the price by going to war in Iran or whether it's the tariffs that are taxed we're gonna fight against Trump [21:18] I absolutely have said over and over yes I do yes I let me just be consistent I have medical for all is a form of single -payer for more than 30 years I have been a proponent an author of legislation for Medicare for Medicare for all which is a form of single -payer and I've done that over and over now what I will tell you is this Ryan what we have to do because people in California don't care what you call it at the end of the day what they want is access to a doctor when they need it and a bill that they can afford to pay and that's what we'll do and when I was secretary I advance more coverage for more Americans than ever before and we lower prices [23:21] sure with with with friends like that who needs enemies right first it's hard to respond to lies we did not dismantle we actually increased oversight in fact [23:32] in fact what we did was we increased oversight over nursing homes because nursing homes had been the place where more deaths occurred as a result of COVID so we actually increased oversight and what I will tell you is this the record speaks for itself Steve under my watch we went to more than 300 million Americans who had health care coverage that was far beyond what Donald Trump your daddy gave us and we are going to continue to move forward in California [24:07] I can because as I've said from day one I was not involved in the wrongdoing I had nothing to do with that I did nothing wrong and don't take my words for it take the words of the u .s. attorney who said no candidate running for governor has been implicated in this particular matter so Steve you may not want to accept it but the truth is what it is you don't get to make up the facts your chief of staff who said [24:40] if I can respond to that if I can respond to that the the district the the prosecuting attorney in the u .s. attorney's office is the one that handled this case Steve unless you've tell me otherwise I don't think you've gone to law school but the u .s. attorney did say and [24:56] Katie to your point then that the the u .s. attorney has said no candidate including me running for governor has been implicated in this case and they looked at all the facts and decided that there was no involvement on my part they want to continue to repeat saying that I get it because it's a campaign except the facts [27:15] this is what happens when you take the lead in the polls and you're ahead of everyone else they all come at you so I get it I'm getting [27:24] it I get it I get it so there they have to try to beat down this is a great Trump tactic that's used I didn't expect it to come from fellow Democrats but it's coming but here's what I will Katie I will quote to you what the US Attorney said no candidate running for governor has been implicated in this case you may not like that but that's what the US Attorney said [32:10] realistically given that we've seen about a hundred a little more than a hundred thousand units built over the last few years if we can double triple that get it to about 300 ,000 that would be a pretty good achievement we have to go beyond that but let's start to unstick the process let's streamline the regulatory process so that we can get developers through the process much quicker let's ask our local governments to stop imposing so many impact fees let's try to make sure that we're working with the local governments to have a statewide coordinated housing policy so it makes sense where we build how we go up we build by transit let's make sure in newer communities we take into account fire hazards and let's make sure that we take into account what property insurance costs because it's hard to buy a house if you can't afford the property insurance for it and so we will do a number of things that's why I've said I will declare a state of emergency when I become a governor to make sure we have the ability the authorities of the governor's office to move this as quickly as possible [40:52] yeah so once again it's it's amazing how people don't read plans and they they try to interpret what other people are saying what I will say to you Matt is this we know what we need to do to try to construct we have to reduce the the regulations that are keeping developers from being able to pencil out projects we know that local governments are very afraid of trying to move too quickly Javier your party if I could just finish Steve and so what we have to do is [41:26] so it's not rocket science what we do have to do is take advantage of what we know can be done quickly there are 40 ,000 shovel ready projects affordable units ready to go if we could just help find the financing when I declare that emergency state of emergency when I get in we will find the money to get those projects on the way but and I will tell you this if you don't believe that we can deal with high home insurance rates Matt then you be running for government we're actually bringing down [42:02] California voters [42:09] do want to [42:13] just finished what is [42:15] just finish the sentence and say yeah [42:22] your [42:27] think [42:30] unfortunate for people for candidates who believe that home insurance costs casualty insurance costs are okay and not try to take this head on grab that bull by the horns because too many families are not able to afford their places their homes because how in home insurance rates have gone sky -high I will tackle that and watch [51:55] Thank you very much. [52:16] so I get a minute to respond to the question in a 30 seconds to respond to miss Porter [52:21] okay so I'll respond to your question and if you give me 30 seconds I'll respond to Katie's question so on artificial intelligence we want to make sure that when artificial intelligence is based here and it should be based here because this is the home of artificial intelligence that it is doing more than just taking care of its own needs it is helping take care the needs of communities that are in California because it is an industry that is going to offer us great opportunity at the same time we want to make sure we're offering the protections that our families need our children our workers we have to make sure that as we harness AI we do it before AI harnesses us and so that means taking advantage of working with them to establish a clear set of rules on how they will operate they will provide resources to have the infrastructure that they need but also expand that to provide the California people with a little extra and we'll do this without imposing the type of regulation that would move them over to places like China. [53:26] Absolutely as the only person who's actually done tax policy because I sat on the Ways and Means Committee for 20 years in the House of Representatives I can tell you what we will do Katie we will make sure that we change the tax code so we don't just tax doctors and nurses and firefighters and teachers at rates that are higher than billionaires like Tom Steyer what we will do is make sure that everyone pays their fair share that won't be so difficult if you look at the governor's budget from this that from today in fact he actually calls for getting rid of some of the corporate welfare loopholes that are allowing corporations to pay less we have the resources to go out and create the revenue we need and we'll make sure that everyone is paying their fair share. We'll make [57:04] Sure Tom. Just look at my record. When I was Attorney General I sued the fossil fuel companies over and over. When I was Attorney General I took on Donald Trump who tried to eliminate California's clean car standards and we beat him. When I was Attorney General I sued oil companies who were trying to monopolize an industry and we beat them. I will stand on my record. I won't have to talk about inflated promises because I could show people what I've done when I was AG and what I will do as governor to make sure that we continue to move towards a transition to clean energy. [57:41] Javier Becerra [58:13] Absolutely not. [66:41] We should not let anyone, whether it's a union or whether it's administrator, get in the way of accountability. We have an obligation and we have laws that require us to make sure that we are enforcing all the obligations that whether you're a classroom teacher or whether you're that principal, you have obligations. As the former chief law enforcement officer for the state of California, we will make sure that we hold people accountable. But the other thing we have to do is recognize that holding people accountable for getting kids to be ready to go to college is a little late. We have to start early because we're baking in mediocrity by not helping children before they even get into kindergarten. And so we have to start much earlier. Child care must be somewhere, a place where people actually get their kids to learn because we want them to be ready not just at the third grade or the sixth grade or the 12th grade. We want them ready before they start kindergarten. And I believe it's time to start going in the direction of early childhood education. And I believe it's time that we started to reduce class size so that it's manageable. No teacher should be asked to take care of 30, 40 kids in one classroom. Expect them to become the next scientists and engineers of our state. [73:21] 67 percent of Californians voted for a woman's right to choose. Thank [73:29] Absolutely no, and when I was AG, I protected reproductive rights here in California. [76:42] I could not support a candidate who would be endorsed by or be supported by Donald Trump because we would have a Donald Trump look -alike in the governor's office, and we can't afford to do that. I would support any of the Democrats who are on this stage. [82:42] I have taken on reckless governments. I have taken on ruthless corporations. I've defended workers' rights, women's health, immigrant rights. I've launched civil rights investigations. I launched 988, the suicide and mental health prevention lifeline. I have overseen a budget larger than the budget of the state of California, four times balancing it. I have declared a state of emergency the only candidate who can say that at the national scale. I have taken on those who are ruthlessly trying to stop Californians for having an opportunity to fight. Not just fight, but to win. I'm the only person who can tell you that the moment I walk into that office, I've been through a challenge that you face when you become the governor of the fourth largest economy in the world. And what you don't need is someone who needs training wheels the moment they walk into that governor's office. We need an adult in the room. And as you've seen today, oftentimes in these candidates, it goes lacking. I hope that what we will do is vote for someone who knows how to manage this crisis on day one.

---
snapshot_id: adaea034-dd25-53b6-a279-fd897af4f1f3
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/economy-and-affordability/

Economy and Affordability - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Economy and Affordability Lower Costs. Raise Stability. Put Families First. Californians are being squeezed by rising costs—from insurance and childcare to groceries—and too many families are falling behind even while working hard. This affordability crisis isn’t about people working harder or budgeting better; it’s about systems that have stopped working for everyday Californians. As governor, I will take on the cost of living head-on by standing up to price gouging and unjustified rate hikes, expanding help with childcare and essential costs, and using the power of the state to lower prices where the market has failed. No family should have to choose between caring for their kids, putting food on the table, and staying insured. As the Attorney General of California, I took on hospital systems like Sutter to stop their unlawful anticompetitive practices that let them control and inflate higher health care prices for Californians. And as U.S. Secretary for Health and Human Services, toughened Medicare drug price negotiations to secure significant discounts on high‑cost medicines, capped out‑of‑pocket costs for seniors, and launched innovative models aimed at lowering prescription drug costs and increasing access for Medicare and Medicaid beneficiaries. I’ve tackled affordability before to protect consumers, and will continue the fight as Governor of California. California should work for the people who live and work here, not just those at the top—and my administration will make affordability a top priority across every part of state government. Up Next Energy & Utilities Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 3f12be35-95d2-50ca-ad7d-5414001c3218
source_kind: transcript
url: https://www.youtube.com/watch?v=-_LHkpd7PcM

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [5:15] thank you my parents came to California with $12 in their pocket they worked really hard they never had a chance to go to college but they gave my three sisters and I that very opportunity and as a result we got to live the California dream but too many families today don't believe that the California exists today for them that's why I've been fighting all my public life to make sure that people get to experience what a construction worker and a clerical worker without a college degree had a chance to do that's why I fought to protect the Affordable Care Act when Donald Trump tried to eliminate it the first time he was president and I took him all the way to the Supreme Court and we beat him that's why I had to go at him toe -to -toe over and over more than 120 times when I was attorney general and we beat him whether it was saving the DACA program or whether it was making sure that we protected our families against ICE we fought and we won we're gonna do the same thing again because today it's housing it's health care people want a fighter people want someone with experience I hope to gain your vote [20:10] right in the same way I did it when I was attorney general we establish a bureau that dealt with medical fraud working with the federal government unfortunately Trump is a problem because Trump took a trillion dollars out of the health care system out of the Medicare or them excuse me the Medicaid and the medical system Trump is now trying to deprive California of another billion dollars in health care for medical he doesn't have the right to that you still have to prove that there's been fraud and abuse he is in advance taking money even though he hasn't proven in court what he's done so we should go after him the way I had to do over a hundred and twenty times when I was attorney general we will fight to get those tax subsidies under the Affordable Care Act back for California families we will fight to make sure we get the money that we sent to the federal treasury for medical in California because otherwise three million Californians are in jeopardy of losing their health care we won't let Trump get in our way and whether it's the Trump gas tax because he's recreates a fight the price by going to war in Iran or whether it's the tariffs that are taxed we're gonna fight against Trump [21:18] I absolutely have said over and over yes I do yes I let me just be consistent I have medical for all is a form of single -payer for more than 30 years I have been a proponent an author of legislation for Medicare for Medicare for all which is a form of single -payer and I've done that over and over now what I will tell you is this Ryan what we have to do because people in California don't care what you call it at the end of the day what they want is access to a doctor when they need it and a bill that they can afford to pay and that's what we'll do and when I was secretary I advance more coverage for more Americans than ever before and we lower prices [23:21] sure with with with friends like that who needs enemies right first it's hard to respond to lies we did not dismantle we actually increased oversight in fact [23:32] in fact what we did was we increased oversight over nursing homes because nursing homes had been the place where more deaths occurred as a result of COVID so we actually increased oversight and what I will tell you is this the record speaks for itself Steve under my watch we went to more than 300 million Americans who had health care coverage that was far beyond what Donald Trump your daddy gave us and we are going to continue to move forward in California [24:07] I can because as I've said from day one I was not involved in the wrongdoing I had nothing to do with that I did nothing wrong and don't take my words for it take the words of the u .s. attorney who said no candidate running for governor has been implicated in this particular matter so Steve you may not want to accept it but the truth is what it is you don't get to make up the facts your chief of staff who said [24:40] if I can respond to that if I can respond to that the the district the the prosecuting attorney in the u .s. attorney's office is the one that handled this case Steve unless you've tell me otherwise I don't think you've gone to law school but the u .s. attorney did say and [24:56] Katie to your point then that the the u .s. attorney has said no candidate including me running for governor has been implicated in this case and they looked at all the facts and decided that there was no involvement on my part they want to continue to repeat saying that I get it because it's a campaign except the facts [27:15] this is what happens when you take the lead in the polls and you're ahead of everyone else they all come at you so I get it I'm getting [27:24] it I get it I get it so there they have to try to beat down this is a great Trump tactic that's used I didn't expect it to come from fellow Democrats but it's coming but here's what I will Katie I will quote to you what the US Attorney said no candidate running for governor has been implicated in this case you may not like that but that's what the US Attorney said [32:10] realistically given that we've seen about a hundred a little more than a hundred thousand units built over the last few years if we can double triple that get it to about 300 ,000 that would be a pretty good achievement we have to go beyond that but let's start to unstick the process let's streamline the regulatory process so that we can get developers through the process much quicker let's ask our local governments to stop imposing so many impact fees let's try to make sure that we're working with the local governments to have a statewide coordinated housing policy so it makes sense where we build how we go up we build by transit let's make sure in newer communities we take into account fire hazards and let's make sure that we take into account what property insurance costs because it's hard to buy a house if you can't afford the property insurance for it and so we will do a number of things that's why I've said I will declare a state of emergency when I become a governor to make sure we have the ability the authorities of the governor's office to move this as quickly as possible [40:52] yeah so once again it's it's amazing how people don't read plans and they they try to interpret what other people are saying what I will say to you Matt is this we know what we need to do to try to construct we have to reduce the the regulations that are keeping developers from being able to pencil out projects we know that local governments are very afraid of trying to move too quickly Javier your party if I could just finish Steve and so what we have to do is [41:26] so it's not rocket science what we do have to do is take advantage of what we know can be done quickly there are 40 ,000 shovel ready projects affordable units ready to go if we could just help find the financing when I declare that emergency state of emergency when I get in we will find the money to get those projects on the way but and I will tell you this if you don't believe that we can deal with high home insurance rates Matt then you be running for government we're actually bringing down [42:02] California voters [42:09] do want to [42:13] just finished what is [42:15] just finish the sentence and say yeah [42:22] your [42:27] think [42:30] unfortunate for people for candidates who believe that home insurance costs casualty insurance costs are okay and not try to take this head on grab that bull by the horns because too many families are not able to afford their places their homes because how in home insurance rates have gone sky -high I will tackle that and watch [51:55] Thank you very much. [52:16] so I get a minute to respond to the question in a 30 seconds to respond to miss Porter [52:21] okay so I'll respond to your question and if you give me 30 seconds I'll respond to Katie's question so on artificial intelligence we want to make sure that when artificial intelligence is based here and it should be based here because this is the home of artificial intelligence that it is doing more than just taking care of its own needs it is helping take care the needs of communities that are in California because it is an industry that is going to offer us great opportunity at the same time we want to make sure we're offering the protections that our families need our children our workers we have to make sure that as we harness AI we do it before AI harnesses us and so that means taking advantage of working with them to establish a clear set of rules on how they will operate they will provide resources to have the infrastructure that they need but also expand that to provide the California people with a little extra and we'll do this without imposing the type of regulation that would move them over to places like China. [53:26] Absolutely as the only person who's actually done tax policy because I sat on the Ways and Means Committee for 20 years in the House of Representatives I can tell you what we will do Katie we will make sure that we change the tax code so we don't just tax doctors and nurses and firefighters and teachers at rates that are higher than billionaires like Tom Steyer what we will do is make sure that everyone pays their fair share that won't be so difficult if you look at the governor's budget from this that from today in fact he actually calls for getting rid of some of the corporate welfare loopholes that are allowing corporations to pay less we have the resources to go out and create the revenue we need and we'll make sure that everyone is paying their fair share. We'll make [57:04] Sure Tom. Just look at my record. When I was Attorney General I sued the fossil fuel companies over and over. When I was Attorney General I took on Donald Trump who tried to eliminate California's clean car standards and we beat him. When I was Attorney General I sued oil companies who were trying to monopolize an industry and we beat them. I will stand on my record. I won't have to talk about inflated promises because I could show people what I've done when I was AG and what I will do as governor to make sure that we continue to move towards a transition to clean energy. [57:41] Javier Becerra [58:13] Absolutely not. [66:41] We should not let anyone, whether it's a union or whether it's administrator, get in the way of accountability. We have an obligation and we have laws that require us to make sure that we are enforcing all the obligations that whether you're a classroom teacher or whether you're that principal, you have obligations. As the former chief law enforcement officer for the state of California, we will make sure that we hold people accountable. But the other thing we have to do is recognize that holding people accountable for getting kids to be ready to go to college is a little late. We have to start early because we're baking in mediocrity by not helping children before they even get into kindergarten. And so we have to start much earlier. Child care must be somewhere, a place where people actually get their kids to learn because we want them to be ready not just at the third grade or the sixth grade or the 12th grade. We want them ready before they start kindergarten. And I believe it's time to start going in the direction of early childhood education. And I believe it's time that we started to reduce class size so that it's manageable. No teacher should be asked to take care of 30, 40 kids in one classroom. Expect them to become the next scientists and engineers of our state. [73:21] 67 percent of Californians voted for a woman's right to choose. Thank [73:29] Absolutely no, and when I was AG, I protected reproductive rights here in California. [76:42] I could not support a candidate who would be endorsed by or be supported by Donald Trump because we would have a Donald Trump look -alike in the governor's office, and we can't afford to do that. I would support any of the Democrats who are on this stage. [82:42] I have taken on reckless governments. I have taken on ruthless corporations. I've defended workers' rights, women's health, immigrant rights. I've launched civil rights investigations. I launched 988, the suicide and mental health prevention lifeline. I have overseen a budget larger than the budget of the state of California, four times balancing it. I have declared a state of emergency the only candidate who can say that at the national scale. I have taken on those who are ruthlessly trying to stop Californians for having an opportunity to fight. Not just fight, but to win. I'm the only person who can tell you that the moment I walk into that office, I've been through a challenge that you face when you become the governor of the fourth largest economy in the world. And what you don't need is someone who needs training wheels the moment they walk into that governor's office. We need an adult in the room. And as you've seen today, oftentimes in these candidates, it goes lacking. I hope that what we will do is vote for someone who knows how to manage this crisis on day one.