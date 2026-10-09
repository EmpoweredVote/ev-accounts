You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-defense-spending/labels/coder-3.json. Write JSON only, matching
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

### topic_key: defense-spending
topic_id: 3fd1aa81-e032-4335-8785-452ed10ce9ce  served_revision_id: 5b75a7a2-1a72-436f-be9a-e60cf9ffada5
Question: How much should the government spend on the military?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


## Sources

---
snapshot_id: fce734c6-b0a5-5944-92ea-79e7394c7c3f
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/healthy-food-for-kids

Saved from https://stevehiltonforgovernor.com/policies/healthy-food-for-kids (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA THE WORLD LEADER IN HEALTHY FOOD FOR KIDS ← POLICY ARCHIVE MAKING CALIFORNIA THE WORLD LEADER IN HEALTHY FOOD FOR KIDS STEVE HILTON’S PLAN FOR HEALTHY CALIFORNIA FOOD IN SCHOOLS OVERVIEW California is the food capital of America. California grows it. California pays for the meals. Yet too often California kids are fed ultra-processed junk trucked in by giant out-of-state food-service companies. That is insane. California already guarantees free breakfast and lunch to every student who wants one. Now it should guarantee that at least one of those meals is fresh, healthy, and 100% California-sourced. As governor, Steve Hilton will build on the great progress that has been made under Gavin Newsom, including efforts spearheaded by Jen Newsom, to make this vision a reality. Programs like Farm to School and the KIT program (Kitchen Infrastructure and Training) provide a strong foundation. Now we need to finish the job and bring these benefits to every school district, every school, every student, every day. We are the richest state in the richest nation on earth, with the most fertile farmland and best, most innovative agriculture industry on the planet. We grow the healthy food that we should want people to be eating: produce, fruit, nuts. Our tax dollars should be supporting both the health of our children and the health of our ag industry and our farmers, many of whom have been working the land here for generations but are now struggling thanks to bad policies on water, energy and labor regulation. There is no reason why California shouldn’t be the undisputed world leader in healthy, local food for kids. Decades ago, Alice Waters in Berkeley sparked a global food revolution - simple, fresh, local, seasonal - and with her Edible Schoolyard movement led the way for the revolution to embrace our schools as well. Now there must be no excuses and no delay. No state money for ultra-processed food. No giant food-service company getting state contracts to serve out-of-state food or junk. And every child should get the chance, the knowledge, and just as importantly the time, to grow, cook, eat and understand real food. THE PROBLEM California schools will serve nearly one billion meals this year. That is enormous buying power. California produces the food that nourishes America: nearly half the nation's vegetables and more than three-quarters of its fruits and nuts. So why are California kids not eating it? Why are California tax dollars flowing to huge industrial food-service companies whose business model is food made for shelf life, not health? Why are parents checking every ingredient while California farms can grow almost everything a child needs to eat well? Jennifer Siebel Newsom has done fantastic work championing the Farm to School program. It is exactly what we need, and now should be expanded and extended. Corollary programs like KIT (School Kitchen Infrastructure and Training) and of course School Meals for All should work in closer harmony, with greater reach. The Newsoms have also begun the vital work to get ultra-processed food out of school meals. But the law does not fully take effect until 2035. A child starting kindergarten today could graduate before the job is done. Childhood obesity, anxiety, diabetes, and chronic illness should not wait for another decade of reports and roll-outs. California should be the good food capital of America and indeed the world. It is absurd that this is not already true in California schools. WHAT STEVE WILL DO A HEALTHY CALIFORNIA MEAL IN EVERY SCHOOL, EVERY DAY Every school will serve a healthy meal every day that is 100% California-sourced. Not occasionally. Not only in districts with a grant writer. Every day. Steve will build on Farm to School but set one standard for the whole state: food grown, raised, or made in California. This would be a massive win not only for our children but for our great farmers and ranchers in California. Steve will lead a new effort to tighten up and enforce definitions, to track the food that ends up in our schools, and reject any federal regulations or procurement rules that stand in the way of California’s ambition. (Of course there will be a very small number of food items that cannot be 100% California-sourced, and such limited exceptions will be permitted.) NO CALIFORNIA TAX DOLLARS FOR ULTRA-PROCESSED FOOD Steve will end California state spending on ultra-processed food for children. This has already been legislated but as so often in California, is not properly implemented or enforced. One of the barriers is the lack of an agreed-upon definition. As governor, Steve will fast track the definition and the ban, prioritizing the voices of families, farmers and health professionals, not the Big Food lobby. And in order to fully implement the ban on Ultra-Processed Food, we also need to fast-track fresh food preparation infrastructure and training. PUT CALIFORNIA FARMERS FIRST Steve will end state contracts with giant industrial food-service providers that use ultra-processed food or food from out of state to feed California children. California will use its buying power to support California farmers, ranchers, fishers, food makers, and regional kitchens. California grows it here. California should serve it here. Steve will work with the federal government to make sure there are no barriers to full implementation and funding. And Steve will work directly with farmers and their representative organizations to create close partnerships for direct sales to schools and other state-supported institutions, ensuring both a guaranteed California market and a better price. AN EDIBLE SCHOOLYARD AT EVERY SCHOOL Alice Waters’ pioneering Edible Schoolyard initiative is a beautiful and practical example of how creative thinking can transform attitudes to food and nutrition, as well as teaching valuable life skills. The Edible Schoolyard concept teaches children how to grow food, cook and prepare fresh, healthy meals, and inform their wider education through food. It’s also about time and human connection: taking the time to sit down and eat a meal together is such an important part of our lives that is being squeezed in a world of convenience and delivery apps. If we can foster food and meal-centered wellbeing at school, it would be a tremendous benefit to our society. As governor, Steve will push for a culture in schools that prioritizes food, food education and proper time to eat together. Specifically, the goal will be to see some form of Edible Schoolyard project in every school, adapted to the space it has. Children should have the chance to grow food, taste food, learn to cook it, and understand the connection between a healthy meal and a rich, healthy life with strong human relationships. PARTNERSHIPS WITH LOCAL RESTAURANTS AND CHEFS Another massive untapped resource for the goals laid out in this paper are our great local restaurants and chefs. They have so much to offer, not just in the school setting but including opportunities for work experience, skills training and personal development. Steve will work with restaurants, chefs, and their professional and representative organizations to foster ties between local restaurants, chefs - whether working or retired - and local schools. GOOD FOOD CAPITAL OF THE WORLD California does not need another program with a nice name and a stack of press releases. It needs a governor who sets a clear goal and helps make it happen in a hands-on, practical way. Healthy, California-sourced food in every school, every day. California: the good food capital of the world, in every way. That is the promise. ← Back to all policies

---
snapshot_id: 2b889300-ad5a-5591-b616-25f21dc123ba
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/rebalancing-californias-carbon-sequestration-strategy

Saved from https://stevehiltonforgovernor.com/policies/rebalancing-californias-carbon-sequestration-strategy (rendered page text, built-in browser, 2026-10-07) POLICY REBALANCING CALIFORNIA’S CARBON SEQUESTRATION STRATEGY ← POLICY ARCHIVE REBALANCING CALIFORNIA’S CARBON SEQUESTRATION STRATEGY A COMMON-SENSE PLAN FOR NATURAL CARBON SEQUESTRATION CALIFORNIA’S CLIMATE POLICY IS FAILING WORKING PEOPLE California politicians have spent years making life more expensive in the name of climate policy while failing at one of the most basic environmental responsibilities of all: properly managing California’s forests, watersheds, and natural lands. Working people are paying more for gas, electricity, housing, and transportation. Bureaucrats regulate how Californians drive, build, travel, and live. Politicians lecture families about reducing their carbon footprint while millions of acres of forest remain dangerously unmanaged. And every year, catastrophic wildfires tear through California, destroying communities, polluting the air, and releasing enormous amounts of carbon into the atmosphere. California already acknowledges that carbon sequestration will be necessary to achieve its long-term climate goals. Even under current state projections, tens of millions of metric tons of residual emissions will remain by 2045. The question is not whether California needs carbon sequestration. The question is whether California pursues those goals by making everyday life harder for working people, or by restoring the natural environment itself. HOW POLITICIANS AND BUREAUCRATS GOT IT WRONG For too long, California’s climate debate has been dominated by politicians and bureaucrats who treat higher costs and more restrictions as the solution to every problem. Instead of restoring forests or improving land management, politicians and bureaucrats focus on restricting how people live: drive less, use less energy, pay more for gas and electricity, and accept a lower standard of living in the name of climate policy. Meanwhile, forests burn. Watersheds deteriorate. Fuel loads build up year after year. Basic land management is neglected while politicians argue about mandates and bureaucrats produce endless regulations. California politicians measure vehicle miles traveled while millions of acres of forest remain dangerously unmanaged. That is backwards. STEVE HILTON’S PLAN FOR NATURAL CARBON SEQUESTRATION If you want to remove carbon from the atmosphere, the obvious place to start is with trees, forests, wetlands, healthy soils, and proper land management. Healthy natural landscapes remove carbon naturally while also reducing wildfire risk, improving water systems, protecting communities, and making California cleaner and safer. This is not an argument against environmental stewardship. It is an argument for practical environmental stewardship instead of ideological environmental policy. As Governor, Steve Hilton will rebalance California’s climate strategy around natural carbon sequestration, wildfire prevention, forest restoration, watershed recovery, and practical land stewardship. At the center of the plan will be the California Conservation Corps Alliance, a large-scale voluntary service initiative focused on restoring California’s natural carbon sinks and improving the state’s forests and landscapes. The program will recruit and employ up to 100,000 young Californians over time in paid conservation and restoration work across the state. The initiative will focus on: planting fire-resilient native trees forest thinning and fuel reduction strategic firebreak construction wetland and watershed restoration soil and habitat recovery long-term forest maintenance restoring California’s natural ability to remove carbon from the atmosphere This is environmental policy people will actually be able to see: healthier forests, cleaner watersheds, reduced wildfire danger, restored open space, and safer communities. The plan will also treat wildfire prevention as a central environmental priority. Catastrophic wildfires release enormous amounts of carbon into the atmosphere while destroying the very forests that should function as natural carbon sinks. Proper forest management is environmental policy. Wildfire prevention is environmental policy. Restoring forests is environmental policy. Steve Hilton will appoint Tom Woodard, founder of Plant With Purpose, as California’s first Director of Natural Climate Restoration. The Director will coordinate statewide efforts related to forest restoration, wildfire prevention, watershed recovery, land stewardship, and nature-based carbon removal. The position will operate within the California Natural Resources Agency, which will be led by former Congressman John Duarte as Secretary of Natural Resources. The California Conservation Corps Alliance will also create meaningful opportunities for young Californians to serve their communities and gain valuable skills in forestry, conservation, wildfire mitigation, watershed restoration, and land management. Instead of telling young people that the future requires sacrifice and decline, California should give them the opportunity to help restore and improve the state itself. The program will be funded through regulatory reform savings, streamlined permitting, public-private partnerships, philanthropic partnerships, and reprioritizing existing climate and land management spending. No new taxes. California already spends billions on climate programs, wildfire response, overlapping bureaucracies, and regulatory systems that produce little visible improvement in the environment itself. This plan redirects resources toward practical, measurable environmental improvements that Californians will actually see and experience in their daily lives. A BETTER ENVIRONMENTAL FUTURE FOR CALIFORNIA California should lead the nation in environmental stewardship. But real environmental leadership means improving the environment itself, not simply making life more expensive for working people. For too long, politicians and bureaucrats have approached climate policy through restrictions, mandates, and economic pressure while neglecting forests, watersheds, and natural lands. California can take a better path. By focusing on natural carbon sequestration, forest restoration, wildfire prevention, and practical land management, California can reduce carbon emissions while making the state cleaner, safer, healthier, and more beautiful for future generations. That is what practical environmental stewardship looks like. ← Back to all policies

---
snapshot_id: a322bcfb-2fa7-5f7d-b533-721e72bf0b2e
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california

Saved from https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california (rendered page text, built-in browser, 2026-10-07) POLICY A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA ← POLICY ARCHIVE A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA Steve Hilton’s Plan to Stop Wildfires Before They Become Disasters THE PROBLEM Wildfires are no longer rare emergencies in California. They are a permanent threat. Every year, families lose their homes, communities are torn apart, insurance becomes more expensive or disappears entirely, and billions of dollars are spent reacting after the damage is done. We grieve, we rebuild slowly, and then we wait for the next one. This is not inevitable. Fire is part of California’s natural environment. Catastrophic fire is not. The scale and frequency of today’s disasters are the result of human choices, policy failures, and a system built around reaction instead of prevention. California does not lack firefighters, courage, or money. What we lack is a serious prevention strategy. WHY THE CURRENT APPROACH ISN’T WORKING California’s wildfire policy is reactive by design. It is built to mobilize after catastrophe, not to prevent it. That design did not happen by accident. It is the product of one-party Democratic rule in California, which has dominated state government for more than a decade and shaped how wildfire policy is written, funded, and enforced. Under Democratic control, the state has: Prioritized emergency reactivity and press conferences over long-term prevention. Made forest and brush management slower, more expensive, and harder to do through permitting, lawsuits, and extremist environmental regulation. Failed to deploy modern early detection systems, even as the technology has become affordable and reliable. Diverted fire spending towards growing government programs instead of reducing risk on the ground. Left homeowners and communities to navigate fire hardening on their own, with little support and lots of red tape. Allowed insurance risk to grow unchecked instead of reducing it through prevention. The system rewards reaction and paperwork. It punishes prevention. As a result, California has built a wildfire policy that looks busy but does not actually reduce risk. Fires keep getting bigger, more destructive, and more expensive even as spending keeps rising. That is what Democrat one-party rule produces: more bureaucracy, more process, more spending, and worse results. THE PLAN As governor, Steve Hilton will flip the model from reaction to prevention, making California the first place in the world where wildfire prevention is universal, modern, and proactive. Statewide Detection and Technology Deployment. Deploy modern detection and suppression technology statewide and reform procurement and regulatory rules so California can actually use and scale these tools quickly. A Modern Fire Force. Create a focused California Fire Force dedicated to early detection, rapid suppression, and deployment of modern technology including drones, automated systems, and advanced monitoring. End the Regulatory Barriers That Make Fires Worse. Roll back and reform extreme environmental and air quality regulations that have been weaponized to block basic fire prevention and firefighting. This includes fixing harmful air quality bureaucracy that has been used to stop controlled burns, reforming endangered species rules that prevent effective vegetation management and emergency response, and restoring common-sense authority for fire agencies to act. This will be achieved through executive orders and appointments of serious, results-driven leadership to key agencies like CARB, the Santa Monica Mountains Conservancy, and related regulatory bodies. Universal Fire Protection for Homes. Every home in a fire risk zone becomes eligible for state-supported fire prevention treatments. This is not a mandate. It is an incentive-driven system that makes prevention easy, affordable, and normal. These treatments include fire-retardant coatings for vegetation, decks, fences, and structures; ember-resistant upgrades and defensible space treatments; and modern non-toxic fire suppression and retardant technologies. Align Insurance With Prevention. Reform insurance regulation so insurers can and must offer meaningful premium discounts for fire-hardened homes and co-fund prevention programs, because preventing losses costs less than paying for disasters. Reward Fire Safety. Provide property tax credits for homeowners who complete certified fire prevention upgrades and streamline permits so people can protect their homes quickly. Fix Emergency Readiness and Response. Launch an immediate and comprehensive review, reporting within 90 days, of fire and emergency response capacity in high-risk counties and major cities to ensure the devastating failures exposed in Los Angeles under Mayor Karen Bass never happen again. This includes reviewing water availability and infrastructure, including reservoirs and hydrants, equipment readiness, personnel deployment, and inter-agency coordination. Steve Hilton will appoint an Emergency Preparedness and Response “A Team” of world-class professionals to lead this effort and set new statewide standards for readiness, coordination, and accountability. Open the Door to Innovation. Reform state procurement rules so California can actually use modern detection, suppression, and prevention technologies instead of blocking them with bureaucracy. This plan is informed by the work of Rick Crawford, former Los Angeles Fire Department Battalion Chief, whose California All-Risk Governance Doctrine documents the leadership, infrastructure, and coordination failures exposed by the Palisades Fire. His analysis reinforces the need to shift from reactive response to permanent, accountable readiness before the next disaster strikes. WHAT THIS WOULD MEAN FOR CALIFORNIANS Fewer fires would become disasters because early detection and suppression would stop fires while they are still small. Homes would be safer because fire-hardened properties would be far more likely to survive. Insurance would become affordable again because lower risk would mean lower premiums and more insurers willing to operate in California. Communities would be more stable with fewer evacuations, fewer rebuilds, and fewer families displaced. Taxpayer money would be spent smarter, because prevention costs a fraction of emergency response and rebuilding. Together, these changes would restore something Californians have lost: confidence that their government is actually working to keep them safe. ← Back to all policies