You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-healthcare/labels/coder-2.json. Write JSON only, matching
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

politician_id: 9a60d603-194d-410f-ae01-85bd6293f1a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Steve Hilton — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: healthcare
topic_id: e8dad4a8-eb93-4931-91f5-d8fb5d7dd529  served_revision_id: 87719e15-58aa-4729-a73f-d47e64d5a954
Question: What role should government play in healthcare access?
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


## Sources

---
snapshot_id: 92bcee53-75f3-51f7-8b31-d67822ea95bd
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:14] >> Are we ready to save our beautiful state of [0:37] >> Democracy is under threat. >> Everyone agrees we need change. That's what I'm fighting for. [1:17] >> We can turn things around. You just have [7:39] >> So Caitlyn and Alex, it's interesting. We've already seen a couple of things that we'll probably see a lot of in this debate, which is the Democrats who are here who've been responsible for 16 years of one party rule for everything that we see in California won't take responsibility and all they can talk about is Trump. Look, I was asked how I'm preparing for this debate the other day. And my answer was the meetings, the thousands of people that have come to our events the last year in California. I've traveled to every part of the state. I've seen the struggle and the stories and that is my struggle and my stories. My parents were immigrants. The California dream is my dream and I want that for every single one of you watching out there. We can get it [8:39] >> So, they should vote for the candidate who's got a concrete plan to make our state calffordable. $3 gas, cut your electric bills in half, your first hundred grand taxfree, a home you can afford to buy. It's common sense, practical things. Most of my career has been in business. I know how to get things done. And we need to change. We need some fresh thinking. after 16 years of one party rule from these Democrats that have given us the highest poverty rate as you mentioned the highest unemployment rate and the highest cost of living in the country. [10:06] ahead. >> It's not Donald Trump who's given us gas prices $2 higher than the rest of the country. It's Democrat policies, which Antonia and all the Democrats here support. It's not Donald Trump that's given us the highest housing costs in the country. It's Democrat policies that all these Democrats support. Donald Trump is the president in all the other states of America where the cost of living is way lower than in California. Obviously, it is way past time for change in California and endlessly going on about Donald Trump doesn't serve the needs of the struggling families and small businesses. >> Can you say whether or not he won the election? [14:23] Hilton. >> So, so Matt says that it's obviously impossible to get to $3 gas. Um, as I have laid out in my plan, before the Iran war, there were 40 states in America with $3 gas or lower, most of the which don't have the abundant oil reserves that we have in California. But because of the policy supported by Matt and all these Democrats, we are now shipping oil halfway around the world, 7,500 miles from places like Iraq instead of opening up California oil and gas production so we can reduce costs and get $3 gas in California, which is my plan. [15:00] >> Secretary Bera. [24:05] >> It is. There's there's a very simple truth uh which everyone in California knows which is that taxes are too high and we need taxes to be lower and they're especially too high for working people in California. You got people on 70 80 90 grand in California which doesn't get you very far who are paying 9.3% state income tax. That is higher than the top rate in most other states. That's why my plan eliminates state income tax under 100 grand. And by the way, if you think that it can't get worse in California, I've got two words for you. Tom Styer. Under Tommy Styer, the taxes will be higher. Gas prices will be higher. Everything will be higher with Styer. [26:43] >> Thank you, [29:29] >> So I'm I'm the only immigrant on stage. I'm a legal immigrant and Americans support immigration when it is properly controlled. And what we saw under the Biden administration, open borders undermined everybody's support for immigration. And as governor, I've made it very clear although it is the federal government's responsibility to to um determine and implement immigration policy, I think it's important that all the laws are peacefully enforced. And as governor, I would make sure that we work with the federal government to enforce our laws. Expect [30:11] workers? >> The the policy on deportation is the exact same policy that we saw with President Obama. In fact, the numbers of deportations right now in our country and in California are slightly just to clarify your point. Can you answer the question? I answered the question which is I will work. >> Will you deport him? >> That was the question. >> Well, would you Antonia? Because the governor of California, as you know, doesn't make that decision. It is the president of the United States elected by the country. [34:43] >> I I don't want to respond to to silly name calling, but I'd like to actually respond to something Katie said, and I think it's probably a sincere policy um difference between us. She said something very revealing which is the only way really that California's economy has been growing in the last few years is through illegal immigration. And I just don't think that's the right way for us to be growing. I think we need to help small businesses create jobs and opportunity and for Californians to be able to earn more and live the California dream and for entrepreneurs to want to start businesses in California. That's how we should be growing our economy, not by [35:23] consequences of that decision, >> Katie, it's I there's a difference I think you'll accept between legal and illegal immigration. [43:18] Hilton, >> um Antonio mentioned uh me earlier and said I just recently arrived. It's true. I arrived here in 2012 with my wife and my two sons. But what's interesting is that um I don't think there's an appreciation of the difference between legal and illegal immigration. I've spent many many times right here in East LA where we are with legal immigrants with families of legal immigrants who really resent the unfairness that we're seeing in California where you have illegal immigrants who are getting free benefits, housing, welfare, and they say to me, "Look, we did it the right way. We worked hard. the right way. Candidates, don't worry. >> We are not getting fairness and we need to restore fairness in our [45:34] >> I think the next governor of California will have to work with the administration and with the president that the American people elected to get good results for Californians. And by the way, my attitude will be to work with the president regardless of party to get good results for Californians. Now, it so happens that we have a president who has endorsed me for governor, and we've discussed how I can work with his team to lower gas prices in California by opening up energy production, to reduce wildfire risk, by proper forest management, to get the fraud and the waste out of our state budget so we can cut taxes. These are all practical ways we can work together to help everyone. >> Thank you, Mr. California. [55:54] singlepayer healthcare. >> Just listen to these Democrats arguing about whether to go left or even further left when that's the direction that's got us into this mess, the highest cost, the highest taxes in the country. I'm the only person here with actual experience of singlepayer healthcare. Both as a patient and as a policy maker. As a patient, it nearly killed me. That's another story we don't have time for. As a policy maker, you end up with the worst patient satisfaction, cost that you can't afford, taxes skyhigh to pay for it. It is a total disaster. And the actual way we deal with health care in this state is to at least stop spending $20 billion a year on free health care for illegal immigrants who [64:17] Court has stopped you from being able to [64:21] that's a lie. My my view is that it's a bit rich for Javier to talk about following the law when he is mired personally in a corruption scandal where his former chief of staff Shan McCcluskey when Javier was appointed by Joe Biden to be health secretary he wanted his chief of staff to go with him. The salary wasn't enough. So what did they do? They took money from Javier's campaign account to top up his salary by funneling it to Dana Williamson, Gavin Newsome's former chief of staff, so that it was paid to this guy's wife. All of that is illegal. It is against state law. It's against federal law. My running mate for attorney general, Michael Gates, has this evening written to Javier Bera to make it clear that when he is attorney general, Javier will be investigated and if necessary, prosecuted for these crimes. [65:21] >> I'm not going to weigh in on something that I don't have the knowledge of the facts on. I trust that Chad is interested in what we should all be interested in, which is ensuring the integrity of our elections and restoring faith in our elections in California. That's why I support voter ID in California. Let's see what these Democrats think of voter ID. [66:24] chief And it was your decision. [66:29] Washington as health secretary and you wanted him by your side. And the reason that the money was transferred is because the salary wasn't high enough. That's why you engaged in this scheme which is [67:47] >> And just today, I launched a new plan for starter homes in California. One of the most heartbreaking things I see is young people, they come to our events and I asked them, "Do you ever see yourself owning a home in California, starting a family here?" And they say, "No, and we're going to have to leave." And that's why we've got to enact a very straightforward plan. Number one, we have to get rid of the regulations that make it two or three times as expensive to build the exact same home in California as in neighboring states. We have to stop the lawsuits filed by the unions who support these Democrats that get in the way of building housing. And to your point, we have to stop trying to force housing into suburban neighborhoods where people don't want it. Instead, we have to build single family homes in the places in our state that do want to expand. That's the plan to make sure that we can restore that California dream of home ownership. It is the heart of opportunity for our young people and it's being taken away by these Democrats and their policies. >> Mayor Mayanm, your response. [81:02] >> Mr. [81:04] Hilton, >> look, this is a very serious moment for California. The ballots are out. They're in your hands. And we have a really big choice to make, which is do we go for another four years of one party rule that's given us the highest taxes for the worst results, the highest poverty rate, highest unemployment rate, highest cost of living, serious policy questions, homelessness. We need to stop homelessness and end it. We need to stop funding fiascos like highspeed rail. We need to lift burdens on our business. That's what this debate needs to be about. And the only way to get the change we need is to [86:13] >> It's classic Democrats, isn't it? What you're hearing. Um, if it moves, tax it. If it still moves, regulate it. And if it stops, move it. I guess they want to subsidize it. Look, the truth is on this we have to have a bit of humility. This is a very fastmoving technology and actually even the people involved in it disagree about its exact consequences. Here are two things that we two practical things we could and should be doing better today. First of all, the real bluecollar jobs that are coming from the AI revolution, they're not happening in California. They're going to Texas and Arizona semiconductor manufacturing. We could get that back by removing regulations. And secondly, our school system is not educating our kids to be able to thrive in the world of AI. We need to [89:30] >> I think that was my word. Would you like [89:32] that charge? >> Again, I don't want to respond to silly insults, but I'll take the substantive point, which is first of all, when Tom talks about um uh tripling subsidies for electric vehicles, let's be clear what that is. That is higher taxes on hardworking Californians driving their gas, cars, and trucks every day so that Tom's rich friends can feel virtuous about saving the climate. The truth is, we need common sense on climate change. It doesn't make sense to import oil from halfway around the world, increasing carbon emissions in the name of climate. It doesn't make sense to allow mega wildfires in our forests that actually release more carbon dioxide than what is saved by all these climate policy. [96:06] Hilton. >> Um, so highspeed rail is an example of the fraud. Um, they've spent billions of dollars. I don't know where the money's gone. It certainly hasn't gone into building anything that actually works. And I just want to make one broader point about fraud. I'm actually running this race in a different way than we've seen before. I've put together a team to run with me. There are other statewide offices. And along with my running mate for state controller, Herb Morgan, and Michael Gates for attorney general, and Gloria Romero for Lieutenant Governor, we've actually been investigating the fraud. Our survey so far suggest that there in the last five years in California, we've had $425 billion dollars of fraud. That's around 80 billion a year, around 20% of the budget. And our team is going to stop it and prosecute it and give money. [96:54] >> real quickly, mayor. [99:59] I guess that would be a good one. [100:00] Clint Eastwood. >> Okay. Mr. Hilton. >> I think there's only one choice really. Jason [102:45] rest of the state? Well, um, if you ask my wife and my sons, often to their great embarrassment, it's that I absolutely hate bureaucracy and ridiculous, pointless rules and regulations that crush the life out of uh, people and businesses and daily experience that we have. And so, I just want to tell everyone, I'm going to be relentless, absolutely relentless in fighting the nonsense that makes life so difficult for each and every one of you. I will not rest until we restore sanity to our beautiful state of

---
snapshot_id: 393a101a-6015-54fc-a4d0-3352322e3ce7
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: c000d7e2-a538-5680-9c40-2bcc9ac5f3ed
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/operation-zero-waste

Saved from https://stevehiltonforgovernor.com/policies/operation-zero-waste (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE ← POLICY ARCHIVE OPERATION ZERO WASTE Cut waste. Cut bureaucracy. Pay for tax relief. INTRODUCTION California’s budget has more than doubled in the last ten years, from $170 billion to over $350 billion. Yet outcomes on every significant measure - from schools, to homelessness to economic performance - are worse. Today California has the highest poverty rate, highest unemployment rate and highest cost of living in America. We also have the highest tax rates. We pay the most and get the least: that is commonly known as a rip-off, and it is past time to end it. California does not need higher taxes. It needs a government that stops wasting the money it already takes. Which is too much. Operation Zero Waste will cut wasteful spending, shrink Sacramento bureaucracy and use the savings to help pay for Steve Hilton’s Califordable tax relief, including making the first $150,000 of income tax-free and establishing an 8% flat tax on income above $150,000. This is just the beginning of Operation Zero Waste, not a comprehensive list of every savings opportunity. We are starting with major areas where substantial savings have already been identified and will continue analyzing state government bloat to find more. Note: Some savings estimates overlap. CANCEL HIGH-SPEED RAIL: $3.78 BILLION California has spent years pouring money into High-Speed Rail while the project has fallen further behind schedule and grown more expensive. The High-Speed Rail Authority’s FY 2026-27 budget includes approximately $3.66 billion in capital spending and $117.9 million in administrative and capital support, totaling roughly $3.78 billion. A Hilton administration will end state support for High-Speed Rail on Day 1, based on State Controller candidate Herb Morgan’s analysis that these payments are illegal, given the enabling legislation for the payments which stipulates that High-Speed Rail should operate without subsidy. The most recent ‘Business Plan’ assumes ongoing public subsidy. 5% EFFICIENCY SAVINGS: $18.89 BILLION Every private sector organization is regularly asked to find efficiency savings. That has never happened in California state government. We are confident that efficiency savings can be found well in excess of 5%, however, for planning purposes we are assuming a modest 5% efficiency saving in the first year. That means reducing reliance on expensive outside contractors, consolidating duplicative legal and accounting services, cutting unnecessary administrative costs, reviewing jobs being performed outside California where there is no operational need, using AI and technology to modernize outdated systems, and eliminating spending that does not produce results. The $18.89 billion estimate shows the scale of savings available from applying just a 5% savings requirement across all state government departments. California taxpayers should expect the same basic cost discipline from state government that any well-run organization would demand. 10% BUREAUCRAT REDUCTION: $2.81 BILLION California’s executive branch has become too large and too expensive. The number of state bureaucrats has ballooned from 215,000 in Gavin Newsom’s first budget to over 250,000 in his final budget. California’s actual performance on every meaningful metric had declined over the same period - indeed nearly 2 million Californians, on net, have moved out of the state. A 10% reduction in executive-branch headcount is estimated to save approximately $2.81 billion based on current salary costs. This will be limited to bureaucracy and administrative bloat, not frontline public safety and essential services. This is one example of how the broader 5% efficiency target can be achieved, so the $2.81 billion should not simply be added on top of the $18.89 billion estimate. MEDI-CAL REFORMS: $11.49 BILLION California needs to bring Medi-Cal spending under control and focus resources on the people the program is intended to serve. Potential savings identified include: Ending state-funded full-scope Medi-Cal for undocumented immigrants: $8.5 billion Medi-Cal asset-limit reforms: $790 million Premium reforms for certain adults 19 and older: $1.1 billion Prospective Payment System rate reforms: $1.1 billion Together, these reforms represent approximately $11.49 billion in potential savings. DEFUND THE HOMELESS INDUSTRIAL COMPLEX California has spent billions on homelessness while the crisis has continued to get worse. Too much of that money is swallowed up by a Homeless Industrial Complex of developers, contractors, consultants and nonprofits that gets paid regardless of results. California is paying roughly $500,000 to $650,000 for a single unit of homeless or affordable housing, compared with approximately $150,000 to $350,000 in other states. In some parts of the state, for example the Bay Area and Los Angeles, there have been instances of per unit costs as high as $900,000 or even $1 million. Bringing California’s costs closer to the national average could save at least $1 billion while delivering the same amount of housing. A full costing will require full access to budgets and contracts. Operation Zero Waste will cap what taxpayers can be charged per unit, bring California’s construction costs back in line with the rest of the country, and stop rewarding politically connected developers and contractors for overpriced projects. Eventual savings could be far higher. ENDING THE NONPROFIT RIP-OFF California taxpayers should not be paying layers of nonprofits and middlemen to distribute government money, especially when taxpayer-funded organizations are engaging in political advocacy and voter mobilization. Examples include: Elevate Youth California: More than $370 million in cannabis-tax funding has been administered through Sierra Health Foundation’s Center, including grants to organizations that also engage in voter registration and mobilization. SOMAH, GRID Alternatives and CEJA: California has committed roughly $1 billion to the solar program. GRID Alternatives helps administer the program and CEJA handles community outreach, while CEJA’s affiliated political organization endorses candidates and mobilizes voters. Examples of financial intermediaries and unjustifiable fees include Community Partners (9% private grants, 15% government), Tides Foundation/Center (Model A full sponsorship or Model C for grantmaking-focused), Social Good Fund (5-10%), Charitable Ventures of Orange County (8-12%, 15% public contracts, $10k minimum fee), San Francisco Study Center, Earth Island Institute, and others such as Fulcrum Arts (7% plus annual fee). Operation Zero Waste will cut unnecessary nonprofit middlemen, demand transparency about where taxpayer dollars ultimately go, and require a clear separation between taxpayer-funded programs and political activity. END VANITY AND POLITICAL SPENDING Taxpayers should not be forced to pay for vanity projects or political activity. Operation Zero Waste will target spending on things like First Partner initiatives, taxpayer-funded governor portraits, and state money that supports political activity such as voter registration and ballot harvesting. CHIRLA: In 2024, CHIRLA received $25.6 million in government funding, approximately 82% of its total revenue, and received roughly $72 million in government funding over three years. Its affiliated Action Fund endorses candidates and conducts political organizing. Political activity by organizations like CHIRLA will be defunded. Government should spend taxpayer money on delivering services, not promoting politicians or political causes. THIS IS JUST THE BEGINNING These are the starting points for Operation Zero Waste. We will continue analyzing state government, department by department, program by program to identify additional savings, including: Overlapping agencies and bureaucracies Duplicative contracts and unnecessary administrative costs Programs that continue spending taxpayer money without producing results. RADICAL TRANSPARENCY Finding waste is only part of the job. Californians should also be able to see where their money is going and what they are getting for it. A Hilton administration will make state spending transparent so Californians can see where their money goes, who receives it and what results taxpayers are getting in return. Modern analytics and AI will help identify duplicative contracts, excessive administrative costs, unusual or fraudulent spending and programs that continue receiving taxpayer money without delivering results. That makes Operation Zero Waste an ongoing process, not a one-time round of savings. We will keep finding waste, make sure promised savings actually happen and hold Sacramento accountable for how taxpayer money is spent, working with State Controller Herb Morgan and his Radical Transparency initiative. Better services. Less bureaucracy. Lower taxes. ← Back to all policies

---
snapshot_id: b35cb482-c7a5-5a18-b97e-600977d36d96
source_kind: pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)
url: https://www.ontheissues.org/Steve_Hilton.htm

Steve Hilton on the Issues Follow @ontheissuesorg On the issues: Steve Hilton Hilton's Profile Governor Match | Other CA Candidates: Antonio Villaraigosa Eleni Kounalakis Eric Swalwell Gavin Newsom Katie Porter Tom Steyer Xavier Becerra Zoltan Istvan CA Governor (Republican challenger) Steve Hilton On the issues>> Wikipedia Ballotpedia Contact Steve Hilton Take the Quiz! VoteMatch CA politicians Governors (2026 election unless otherwise noted; AK : Mike Dunleavy (R,term-limited) vs. Click Bishop (R) vs. Nancy Dahlstrom (R) vs. Tom Begich (D) vs. Jonathan Kreiss-Tomkins (D) vs. Bernadette Wilson (R) vs. Bill Walker (I) AL : Kay Ivey (R,term-limited) vs. Doug Jones (D) vs. Tommy Tuberville (R) vs. Will Boyd (D) vs. Yolanda Flowers (D) AR : Sarah Huckabee Sanders (R,for re-election) vs. Fredrick Love (D) AZ : Katie Hobbs (D,for re-election) vs. Andy Biggs (R) vs. David Schweikert (R) vs. Karrin Taylor Robson (R,withdrew) CA : Gavin Newsom (D,term-limited) vs. Xavier Becerra (D) vs. …

---
snapshot_id: 8f30cb3a-9dce-5bde-a8c6-d35435cee727
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/fd106ffe-d61d-4974-be12-12cea7dec518

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Candidates (CBS News) - Sanctuary State - OTR page: https://ontherecord.empowered.vote/meetings/fd106ffe-d61d-4974-be12-12cea7dec518 - Video: https://www.youtube.com/watch?v=gPfi_eDKkYE - Date on On the Record: 2025-11-20 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [6:13] with ICE? Yes. [6:17] are undocumented >> 100%. Um and the reason is that is is to is in everybody's interest that that happens. Why do we have these scenes of confrontation and chaos and crime going on around immigration enforcement? Remember this is federal law. um you may not like the law, but it is the law. And I think generally speaking, it's a good idea to enforce the law. What is the point of passing laws if you don't enforce them? And so I think the situation where you've got federal agencies trying to enforce federal immigration law and then you actively don't get the cooperation of local and state law enforcement. That's why you end up with ICE raids in communities because they say, "Look, if you helped us and if we could cooperate, you just get identify where the people are or you know, hand them over in the wherever it may be in the criminal justice system, then we wouldn't need to go looking in the community." [7:41] up. >> Correct. That's SB54. That was passed in 2017 when Jared Brown was governor. And I totally disagree with it. And again, there's an argument that it's unconstitutional. a good friend of mine, a guy called Michael Gates, he filed a suit in federal court challenging the constitutionality of that law, SB54. That's working its way through the courts. Um, it's perfectly possible, but that by the time I'm governor, the sanctuary state law will have been overturned. [8:21] >> That was the reason for the sanctuary state law to stop that kind of thing happening. I've got to tell you, I'm a legal immigrant. Um we moved here in 2012, visa, green card, citizenship in 2021, 9 years. I believe in immigration. I believe in legal immigration. I don't believe in illegal. The clue is in the name. It's illegal. Um there are many, opportunities for people to come to America the right way. Um, >> but to be fair, [8:51] >> Well, they shouldn't be walking across the border. I mean, it's illegal. It's illegal. [20:45] and >> of course they everyone it's a human right I agree with that everyone should have access to healthcare we're not a barbaric society right other states do it in a much more limited way, not in this goldplated way that we do here in California. So, I don't think there's any excuse because what is that really? That 12 billion of spending that is basically a subsidy to big business so that they can employ illegal immigrant workers and not pay their healthare because the taxpayer is going to bail them out. I think that's totally [21:43] >> It's interesting because you've got to look at the whole picture. So I agree with the point that this shouldn't be a burden on businesses. But of course, who's going to pay for the single pay? That's a massive tactic. Look, I you know, I was in the UK government. We have the National Health Service in the UK, and that is singlepayer. It's it's a massive component of the budget. It's a nightmare, a massive bureaucracy. People are very unhappy with a lot of the um outcomes. The outcomes are much worse. I nearly died as a result of the failings of a singlepayer health care system. The idea that singlepayer healthcare is some perfect nana is just absolutely not true.

---
snapshot_id: 3c3ef552-deae-5264-9187-e4e0f0424337
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: c4d8deeb-c8e8-5fbc-ace9-ae4e224f0537
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud

Saved from https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD ← POLICY ARCHIVE OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD THE PROBLEM The California State Auditor has warned that weak oversight has opened the door to organized healthcare fraud. Criminals can bill for care that never happened, including by using stolen patient information. Taxpayers lose the money, and the elderly and disabled people these programs are supposed to help can be left without the care they need. Stopping that waste is money the state can save. Steve Hilton and citizen investigator Eric Nissen went to a listed home-health agency in Hollywood and found a locked building, no entry listing for the agency, and a published telephone number that could not be reached. They found those red flags in minutes. State regulators need to check that agency's records and establish whether it has billed taxpayers and whether patients received care. It should not take a citizen knocking on the door to get those questions asked. HOW WE GOT HERE In 2022, the California State Auditor identified signs of large-scale, organized hospice fraud in Los Angeles County. One building in Van Nuys housed more than 150 licensed hospice and home-health agencies, more than the building could hold. The auditor found inadequate checks on licenses and staff credentials, slow investigations, and failures to coordinate between state departments. Those licensing failures sit with the California Department of Public Health. Medicare billing oversight sits with the federal Centers for Medicare & Medicaid Services. The officials who ran those systems owe taxpayers an explanation. Herb Morgan, who is running for State Controller, estimates billions of dollars in potential fraud, waste, and improper payments in Medi-Cal and In-Home Supportive Services, or IHSS. In his white paper, the Medi-Cal figure uses a roughly 10 percent improper-payment band drawn from federal CMS Payment Error Rate Measurement ranges. The IHSS figure uses 12 to 15 percent, reflecting self-reported hours and limited verification. Those are exposure estimates, not a count of proven fraud, and they are the starting point for where to look. California already has provider screening and electronic visit verification. Steve will require the agencies to use those records to check the care being billed and stop fraudulent payments. STEVE'S PLAN On Day One, as part of Operation Zero Waste, Steve will direct the Departments of Health Care Services and Public Health to review high-risk home-health and hospice agencies together. Investigators will check the owners and staff credentials, make unannounced visits to suspect offices, and match billing records to actual patients and services. Agencies must be able to show who delivered the care. When the evidence supports it, the state will suspend Medi-Cal payments, revoke licenses, and refer cases for prosecution. Investigators will trace connected companies so an excluded operator cannot simply reopen under another name, and send evidence of Medicare fraud to federal authorities. For IHSS and home-health visits, Steve will require closer checks of the hours claimed against authorized care and existing visit records. Repeated manual changes, impossible hours, and overlapping claims will trigger review and direct confirmation with the patient or an authorized representative. Live-in caregiver exemptions will be checked in suspicious cases. State agencies will match claims against death records, hospital stays, and excluded-provider lists, blocking clearly invalid claims such as services dated after a patient's death. Families providing genuine care will keep getting paid, with a prompt way to correct errors that could interrupt necessary care. Steve will require additional review before payment for providers with serious billing red flags, then extend those checks to medical transport, equipment, and behavioral-health services. His administration will pursue repayment from fraudulent providers and work with state and federal prosecutors on organized schemes. Medi-Cal health plans will have to account for recovered overpayments, with sustained reductions in improper spending reflected in future payments to plans. Otherwise, taxpayers could keep paying the same amount while the plans pocket the savings. Steve will work with Herb Morgan to check the financial results. When elected Controller, Herb will use the office's independent audit authority to examine high-risk payments and review the savings. He will publish the results under a radical-transparency standard: provider payments, recovery amounts, and exception patterns available to the public, with patient and caregiver identities fully protected. Steve is aiming for $5 billion a year in net savings to California's budget once the changes are in place. Public reports will show the California savings after enforcement costs, with federal savings and one-time recoveries listed separately. Only money California can save every year will be counted as ongoing savings. Within the first 100 days, inspections of suspect agencies and tighter checks on their claims will be underway. Over the following nine months, the administration will strengthen IHSS verification and connect the records needed to catch bad claims before payment. Within 18 months, the controls will extend across the targeted services. Steve will seek any legislation or federal approvals needed to finish the job, and publish the results as the work proceeds. A BETTER WAY FORWARD Families looking for home care should be able to reach the provider and trust that someone will turn up. Taxpayers should be able to see what they are paying for, without seeing anyone's medical record. Steve's administration will make providers and the departments overseeing them answer for that money. Radical transparency will put the financial results in public, and the savings will be reported in public. ← Back to all policies

---
snapshot_id: a1686364-9f4b-512d-96b6-af5f6a5a23f1
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/put-the-people-back-in-charge

Saved from https://stevehiltonforgovernor.com/policies/put-the-people-back-in-charge (rendered page text, built-in browser, 2026-10-07) POLICY PUT THE PEOPLE BACK IN CHARGE ← POLICY ARCHIVE PUT THE PEOPLE BACK IN CHARGE STEVE HILTON’S PLAN TO END PAY-TO-PLAY AND BREAK CALIFORNIA’S CORRUPT MACHINE California families pay some of the highest taxes, utility bills, housing costs and healthcare costs in America. Yet state government listens first to the corporations, lobbyists, contractors and government union bosses who finance the political machine. Xavier Becerra is the product of that system. He first won elected office in 1990. Thirty-six years later, he is asking Californians to promote him again. Over that career, his campaigns have received money from PG&E, Sempra, Southern California Edison, Chevron, healthcare companies, insurance companies, tobacco companies and government union PACs. Now the machine is spending millions to put him in the governor’s office. Outside groups funded by realtors, labor organizations, doctors, Airbnb, Meta, Chevron and DaVita spent approximately $13 million to boost Becerra in the primary. Then there is the corruption scandal inside his own political operation. Three Becerra insiders pleaded guilty to participating in a scheme that diverted approximately $225,000 from his dormant campaign account. Becerra has admitted that he knew about and authorized the monthly payments at the center of the case. He says he was deceived about where the money ultimately went. That is impossible to believe: the entire purpose of the illegal scheme was to enable him to bring his longtime Chief of Staff, Sean McCluskie, with him to Washington DC when he became President Biden’s HHS Secretary. California has had enough of this corrupt, incompetent political machine and its cruel consequences for every working family and small business in California. California’s politicians even exempted the Legislature from the state’s pay-to-play rules. Steve has a decades-long track record of fighting against corruption in politics. His tech start-up Crowdpac was built on a mission to get big money out of politics. Its stated goal was “to make it easier for independent, and independent-minded candidates to run for office without depending on big donors and insider political machines.” In his 2018 book Positive Populism, Steve argued for banning “Conflict Donors.” Steve will bring the spirit and action of an anti-corruption crusader to Sacramento, to clean up the rotten mess left by decades of unchecked sleaze. Steve Hilton will break Becerra’s corrupt machine with four clear reforms. 1. END PAY-TO-PLAY IN THE LEGISLATURE California already has a law designed to stop pay-to-play. Under the Levine Act, someone seeking certain government contracts, licenses or permits cannot contribute more than $500 to the official making the decision. But the Legislature exempted itself. That has to end. If a company, union, trade group or anyone else is lobbying for a bill, budget item, tax break, carveout or special favor, it should not be writing large campaign checks to the lawmakers deciding whether it gets one. Steve will extend the $500 limit to the Legislature. While a matter is pending and for 12 months afterward, anyone lobbying for it will be barred from contributing more than $500 to the lawmakers voting on it. A lawmaker who received more than $500 from that interest during the previous 12 months will have a choice: return the money or step away from the matter. Contributions from affiliated companies, controlled PACs, lobbyists and other agents will be counted together. No hiding a large contribution behind different subsidiaries, political committees or intermediaries. Every covered contribution and lobbying matter will be published in a searchable database within 48 hours. The principle is simple. Make your case. Win the argument. But you do not get to buy access or favorable treatment. California’s current rules, including the $500 threshold and 12-month restrictions, are explained by the Fair Political Practices Commission. The current statute expressly excludes the Legislature. 2. KEEP TAXPAYER MONEY OUT OF POLITICAL CAMPAIGNS Proposition 4 would repeal California’s longstanding ban on using public funds for political campaigns. It would not create a taxpayer-funded campaign system immediately. It would give politicians the power to create one later. Steve opposes Proposition 4. If it passes, Steve will veto any state program or appropriation that puts taxpayer money into political campaigns. Recipients of state grants and contracts will also be required to keep public money completely separate from political spending. There will be real audits and real penalties for violations. California has a massive budget problem. Families are struggling to afford rent, gas, groceries and electricity. The state does not have a shortage of political consultants. Campaigns can raise their own money. The nonpartisan Legislative Analyst confirms that Proposition 4 would repeal the existing prohibition and permit future public campaign-finance programs. 3. OPEN THE BOOKS AND END THE SECRET DEALS The Legislature forces other government agencies to comply with the California Public Records Act. It protects itself with the weaker Legislative Open Records Act. Steve will end this double standard. The California Public Records Act will apply fully to the Legislature, with the same disclosure deadlines, enforcement and public right to challenge improper secrecy. Records of substantiated misconduct by lawmakers will be made public, with appropriate protection for victims and witnesses. Politicians should not be able to hide their own misconduct under rules they wrote for themselves. Recent laws restricting non-disclosure agreements during negotiations over legislation and regulations are a start. Steve will extend the ban to state budgets, contracts, labor agreements, legal settlements and major public-works projects. The governor and senior appointees will disclose meetings with registered lobbyists and major campaign donors within 48 hours. State contracts, grants, settlements, bids, change orders and payments will be published in one searchable public database. No secret agreements. No hidden side letters. No conveniently missing records. 4. OPEN THE CAPITOL AND STOP THE POLITICIANS’ PALACE As of July 2026, taxpayers had already spent $668 million on the Capitol Annex project. The latest estimate is $1.2 billion. That is more than double what was originally proposed. The politicians even spent $5.2 million mining California granite, shipping it to Italy for fabrication and shipping it back. Plans have also included private corridors allowing lawmakers to avoid the public and reporters. Steve will order an immediate independent audit of the project. New change orders and nonessential luxury spending will be paused. Every contract, bid, payment, change order and confidentiality agreement connected to the project will be published. Private escape routes for politicians will be eliminated. Credentialed reporters will retain direct access to question lawmakers. Steve will hold regular, unscripted press conferences as governor. The official project website reports $668 million spent as of July 2026. KCRA’s reporting found that $5.2 million was spent shipping California granite to Italy and back. New reporting puts the latest budget at over $1.2 billion. PEOPLE BEFORE THE MACHINE This is what the contrast in the governor’s race comes down to. Xavier Becerra has spent his career inside the machine. The corporations, lobbyists, consultants and union bosses who benefit from that machine are spending millions to keep it in power. Becerra works for them. Steve Hilton will work for you - for the working people and small businesses who have for years been screwed by Becerra’s corrupt machine. Steve has a decades-long track record of fighting against corruption in politics and he will bring the spirit and action of an anti-corruption crusader to Sacramento, to clean up the rotten mess left by decades of unchecked sleaze. People paying taxes will come before people paying for political campaigns. No favors for donors. No secret deals. No taxpayer-funded campaigns. No politicians hiding from the public. Enough is enough. Throw out the insiders. Let’s fix California. ← Back to all policies

---
snapshot_id: 4024dbe9-6150-5dbd-8a8f-ba21347d85c6
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee

Saved from https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee (rendered page text, built-in browser, 2026-10-07) POLICY THE WORKING CLASS HEALTHCARE GUARANTEE ← POLICY ARCHIVE THE WORKING CLASS HEALTHCARE GUARANTEE Reducing Costs to Make Healthcare Available and Affordable for Working Families in California California politicians boast about how many people have an insurance card. That misses the point. The real test is whether people can see a doctor and afford the bill. Most Californians under 65 get insurance in one of three ways. More than half get it through an employer. More than one-third of Californians rely on Medi-Cal. A much smaller number buy coverage through Covered California or directly from an insurer. Each part of the system works differently, but all three are dragged down by the same problem: California has never seriously confronted the underlying cost of healthcare. Workers pay through payroll deductions, deductibles and lower wages. Medi-Cal patients may pay little or nothing in premiums but struggle to find a doctor. People buying insurance themselves face California's high healthcare costs directly. Steve Hilton will take on the cost of healthcare itself. That means exposing prices, bringing in more providers, cutting out middlemen, stopping fraud and giving patients control over the money spent in their name. That way Steve can deliver the most important missing piece of the healthcare system in California today: a Working Class Healthcare Guarantee - healthcare that is available to working families in California for an affordable premium and with a low deductible that doesn't make a mockery of the whole idea of health insurance. THE PROBLEM Healthcare in California is too expensive and too hard to get. Patients rarely know what a service will cost before receiving it. State rules limit who can provide care and make it harder to open clinics or expand hospitals. Pharmacy benefit managers and other middlemen make money from deals patients never see. The result is predictable. Prices rise. Insurance premiums rise with them. Patients pay more while doctors and independent providers spend more time fighting through bureaucracy. California politicians respond by spending more government money and enrolling more people in government programs. Then they declare success. But more spending is not success if families still cannot afford care, and an insurance card is not much use if nobody will take it. HOW CALIFORNIA GOT HERE Insurance was supposed to protect people from large and unexpected medical bills. It has become a complicated payment system for almost every medical service. Patients do not see the real price, and providers have little reason to compete directly for their business. California made matters worse by piling on mandates, licensing restrictions and approval processes. The biggest institutions learned how to work the system. Smaller providers and patients were left to pay for it. Steve's plan starts from a simple principle: the system should work for the patient, not the people who control the paperwork. THE PLAN 1. CUT THE COST OF EMPLOYER HEALTHCARE Employer coverage is not free. In 2025, the average California employer plan cost more than $10,000 for one person and more than $28,000 for a family. Workers may not see the whole bill, but they pay it through contributions, deductibles and wages swallowed up by rising healthcare costs. Bringing those costs down starts with prices. Hospitals, physician offices, outpatient centers and pharmacies will have to show patients real dollar prices before nonemergency care. California already collects huge amounts of payment data, but much of it is buried in files almost nobody can use. A price hidden in a computer file is not transparency. Steve will put the information on one website where patients and employers can make real comparisons. Prescription drugs are another obvious place to act. California has recently passed restrictions on pharmacy benefit managers, including a ban on spread pricing in new and renewed contracts. Those rules will be enforced and the remaining loopholes closed. The state will publish cash and Health Savings Account prices for the 100 most commonly used generic medicines. Patients will be allowed to pay the lower cash price when it beats the insured price, and unnecessary barriers to lawful mail-order and out-of-state pharmacy competition will go. California also needs more people providing care. Some qualified nurse practitioners can now work independently, but the remaining restrictions are excessive. Steve will finish that reform, give qualified physician assistants greater authority and bring California into the Interstate Medical Licensure Compact so experienced doctors can start practicing here without an unnecessarily slow licensing process. The same approach applies to clinics and hospitals. California already has a 30-day approval process for a narrow group of clinics affiliated with experienced nonprofit operators. Steve will make rapid approval available to any qualified neighborhood clinic that meets clear health and safety requirements. Hospital projects will face firm review deadlines. Limited extensions to California's 2030 seismic deadline already exist, but too many hospitals remain at risk of closing because they cannot meet an arbitrary timetable. Steve will expand the extension process and allow practical plans that protect earthquake safety without taking hospital beds out of a community. California should produce more of its own medicine too. Pharmaceutical enterprise zones in the Central Valley and Inland Empire will offer tax and regulatory relief to companies that actually manufacture essential and generic medicines here. No production and no California jobs means no incentive. These changes attack the costs that drive up employer premiums in the first place. That is how workers keep more of what they earn. 2. REPLACE BUREAUCRATIC MEDI-CAL WITH PATIENT CONTROL Medi-Cal functions as a separate, second-class system: fewer than half of doctors who have signed Medi-Cal contracts accept Medi-Cal patients, reimbursement runs at barely half of Medicare rates, and peer-reviewed outcomes data show Medicaid patients faring worse than comparably situated privately insured patients. California already spends more per Medi-Cal enrollee than the average cost of private insurance per enrollee, yet delivers worse access and outcomes. The problem is the structure of the benefit, not the level of spending. Medi-Cal spends thousands of dollars in a patient's name, but the patient controls almost none of it. Government agencies and managed-care organizations decide where the money goes. The patient gets a card and may still be unable to find a doctor. Fraud drains even more money away from legitimate care. California already has anti-fraud operations inside the Department of Health Care Services and the Attorney General's office, but responsibility is divided. Steve will put them into one California Health Program Integrity command working directly with federal investigators. Modern claims analysis can catch impermissible billing, duplicate identities and excluded providers before payment. Honest mistakes can be corrected. Deliberate theft will mean removal from the program, prosecution and repayment. The larger reform is to give patients control. For working-age adults who are not seniors or disabled, California will seek federal approval for personal healthcare accounts containing approximately $8,000 to $10,000 a year. Preventive care and protection against catastrophic medical costs will remain covered. Patients will use their accounts for qualified healthcare expenses and choose their own providers. Money left over will remain available for future care instead of disappearing at the end of the year. Doctors and clinics will have to compete for the patient rather than the patient begging a bureaucracy for permission. California will pursue a federal Section 1115 demonstration and begin in a region willing to participate. If it works, it can expand. Federal law already requires work or community engagement from many able-bodied Medicaid adults beginning in 2027. California should implement that requirement. Medi-Cal must protect children, seniors, people with disabilities and families going through hard times. It should not become a permanent destination for adults who are able to work. 3. GIVE PEOPLE BUYING THEIR OWN INSURANCE A REAL ALTERNATIVE The individual market covers a much smaller share of Californians, but the people in it feel every increase directly. They include self-employed workers, independent contractors, small-business owners and people who retire before becoming eligible for Medicare. They need a lower-cost alternative focused on what insurance is supposed to do: protect against major medical expenses without making ordinary care unaffordable. Steve's Working Class Healthcare Guarantee will give them access to coverage with an affordable premium and a low deductible. Californians who prefer high-deductible coverage paired with a larger and more flexible Health Savings Account will still have that option. To bring down premiums, Steve will apply for a Section 1332 State Innovation Waiver under the Affordable Care Act. Section 1332 allows a state to redesign its individual insurance market if the new system provides coverage that is at least as comprehensive and affordable, covers a comparable number of people and does not increase the federal deficit. California will use the waiver to establish a reinsurance program. Reinsurance pays part of the small number of exceptionally high medical claims so those costs do not drive up premiums for everybody else. When premiums fall, the federal government spends less on premium tax credits. Section 1332 allows those federal savings to return to California as pass-through funding to help pay for the program. Alaska used this approach through the Alaska Reinsurance Program, which covers claims tied to 34 high-cost medical conditions. Federal officials estimate that premiums are 38.5 percent lower than they would have been without the waiver. Reinsurance directly lowers the premium. California will combine it with existing state assistance and savings from the cost reforms throughout this plan to bring down the deductible too. Covered California's Bronze plans now work with HSAs, but California still refuses to recognize the full federal tax benefits of the accounts. Steve will end that state tax penalty. Qualifying plans will also be able to provide a $500 annual wellness contribution when participants complete eligible preventive care or healthy-lifestyle activities. The same Section 1332 waiver will seek approval for simpler coverage options that protect against major medical expenses without forcing Californians to pay for a long list of mandates they do not want. Californians buying their own coverage should have real choices, including a plan that delivers the affordable premium and low deductible promised by the Working Class Healthcare Guarantee. A BETTER WAY FORWARD California does not lack healthcare spending. It lacks a system that treats the patient as the customer. The current system answers to government agencies, insurers, hospital bureaucracies and middlemen. Steve will make it answer to the patient, and focus on delivering a new Working Class Healthcare Guarantee, with affordable premiums and low deductibles for working families. ← Back to all policies