You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-childcare/labels/coder-3.json. Write JSON only, matching
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


## Sources

---
snapshot_id: 4f26f94a-beda-53f5-b325-2e56478f0897
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee

Saved from https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee (rendered page text, built-in browser, 2026-10-07) POLICY THE WORKING CLASS HEALTHCARE GUARANTEE ← POLICY ARCHIVE THE WORKING CLASS HEALTHCARE GUARANTEE Reducing Costs to Make Healthcare Available and Affordable for Working Families in California California politicians boast about how many people have an insurance card. That misses the point. The real test is whether people can see a doctor and afford the bill. Most Californians under 65 get insurance in one of three ways. More than half get it through an employer. More than one-third of Californians rely on Medi-Cal. A much smaller number buy coverage through Covered California or directly from an insurer. Each part of the system works differently, but all three are dragged down by the same problem: California has never seriously confronted the underlying cost of healthcare. Workers pay through payroll deductions, deductibles and lower wages. Medi-Cal patients may pay little or nothing in premiums but struggle to find a doctor. People buying insurance themselves face California's high healthcare costs directly. Steve Hilton will take on the cost of healthcare itself. That means exposing prices, bringing in more providers, cutting out middlemen, stopping fraud and giving patients control over the money spent in their name. That way Steve can deliver the most important missing piece of the healthcare system in California today: a Working Class Healthcare Guarantee - healthcare that is available to working families in California for an affordable premium and with a low deductible that doesn't make a mockery of the whole idea of health insurance. THE PROBLEM Healthcare in California is too expensive and too hard to get. Patients rarely know what a service will cost before receiving it. State rules limit who can provide care and make it harder to open clinics or expand hospitals. Pharmacy benefit managers and other middlemen make money from deals patients never see. The result is predictable. Prices rise. Insurance premiums rise with them. Patients pay more while doctors and independent providers spend more time fighting through bureaucracy. California politicians respond by spending more government money and enrolling more people in government programs. Then they declare success. But more spending is not success if families still cannot afford care, and an insurance card is not much use if nobody will take it. HOW CALIFORNIA GOT HERE Insurance was supposed to protect people from large and unexpected medical bills. It has become a complicated payment system for almost every medical service. Patients do not see the real price, and providers have little reason to compete directly for their business. California made matters worse by piling on mandates, licensing restrictions and approval processes. The biggest institutions learned how to work the system. Smaller providers and patients were left to pay for it. Steve's plan starts from a simple principle: the system should work for the patient, not the people who control the paperwork. THE PLAN 1. CUT THE COST OF EMPLOYER HEALTHCARE Employer coverage is not free. In 2025, the average California employer plan cost more than $10,000 for one person and more than $28,000 for a family. Workers may not see the whole bill, but they pay it through contributions, deductibles and wages swallowed up by rising healthcare costs. Bringing those costs down starts with prices. Hospitals, physician offices, outpatient centers and pharmacies will have to show patients real dollar prices before nonemergency care. California already collects huge amounts of payment data, but much of it is buried in files almost nobody can use. A price hidden in a computer file is not transparency. Steve will put the information on one website where patients and employers can make real comparisons. Prescription drugs are another obvious place to act. California has recently passed restrictions on pharmacy benefit managers, including a ban on spread pricing in new and renewed contracts. Those rules will be enforced and the remaining loopholes closed. The state will publish cash and Health Savings Account prices for the 100 most commonly used generic medicines. Patients will be allowed to pay the lower cash price when it beats the insured price, and unnecessary barriers to lawful mail-order and out-of-state pharmacy competition will go. California also needs more people providing care. Some qualified nurse practitioners can now work independently, but the remaining restrictions are excessive. Steve will finish that reform, give qualified physician assistants greater authority and bring California into the Interstate Medical Licensure Compact so experienced doctors can start practicing here without an unnecessarily slow licensing process. The same approach applies to clinics and hospitals. California already has a 30-day approval process for a narrow group of clinics affiliated with experienced nonprofit operators. Steve will make rapid approval available to any qualified neighborhood clinic that meets clear health and safety requirements. Hospital projects will face firm review deadlines. Limited extensions to California's 2030 seismic deadline already exist, but too many hospitals remain at risk of closing because they cannot meet an arbitrary timetable. Steve will expand the extension process and allow practical plans that protect earthquake safety without taking hospital beds out of a community. California should produce more of its own medicine too. Pharmaceutical enterprise zones in the Central Valley and Inland Empire will offer tax and regulatory relief to companies that actually manufacture essential and generic medicines here. No production and no California jobs means no incentive. These changes attack the costs that drive up employer premiums in the first place. That is how workers keep more of what they earn. 2. REPLACE BUREAUCRATIC MEDI-CAL WITH PATIENT CONTROL Medi-Cal functions as a separate, second-class system: fewer than half of doctors who have signed Medi-Cal contracts accept Medi-Cal patients, reimbursement runs at barely half of Medicare rates, and peer-reviewed outcomes data show Medicaid patients faring worse than comparably situated privately insured patients. California already spends more per Medi-Cal enrollee than the average cost of private insurance per enrollee, yet delivers worse access and outcomes. The problem is the structure of the benefit, not the level of spending. Medi-Cal spends thousands of dollars in a patient's name, but the patient controls almost none of it. Government agencies and managed-care organizations decide where the money goes. The patient gets a card and may still be unable to find a doctor. Fraud drains even more money away from legitimate care. California already has anti-fraud operations inside the Department of Health Care Services and the Attorney General's office, but responsibility is divided. Steve will put them into one California Health Program Integrity command working directly with federal investigators. Modern claims analysis can catch impermissible billing, duplicate identities and excluded providers before payment. Honest mistakes can be corrected. Deliberate theft will mean removal from the program, prosecution and repayment. The larger reform is to give patients control. For working-age adults who are not seniors or disabled, California will seek federal approval for personal healthcare accounts containing approximately $8,000 to $10,000 a year. Preventive care and protection against catastrophic medical costs will remain covered. Patients will use their accounts for qualified healthcare expenses and choose their own providers. Money left over will remain available for future care instead of disappearing at the end of the year. Doctors and clinics will have to compete for the patient rather than the patient begging a bureaucracy for permission. California will pursue a federal Section 1115 demonstration and begin in a region willing to participate. If it works, it can expand. Federal law already requires work or community engagement from many able-bodied Medicaid adults beginning in 2027. California should implement that requirement. Medi-Cal must protect children, seniors, people with disabilities and families going through hard times. It should not become a permanent destination for adults who are able to work. 3. GIVE PEOPLE BUYING THEIR OWN INSURANCE A REAL ALTERNATIVE The individual market covers a much smaller share of Californians, but the people in it feel every increase directly. They include self-employed workers, independent contractors, small-business owners and people who retire before becoming eligible for Medicare. They need a lower-cost alternative focused on what insurance is supposed to do: protect against major medical expenses without making ordinary care unaffordable. Steve's Working Class Healthcare Guarantee will give them access to coverage with an affordable premium and a low deductible. Californians who prefer high-deductible coverage paired with a larger and more flexible Health Savings Account will still have that option. To bring down premiums, Steve will apply for a Section 1332 State Innovation Waiver under the Affordable Care Act. Section 1332 allows a state to redesign its individual insurance market if the new system provides coverage that is at least as comprehensive and affordable, covers a comparable number of people and does not increase the federal deficit. California will use the waiver to establish a reinsurance program. Reinsurance pays part of the small number of exceptionally high medical claims so those costs do not drive up premiums for everybody else. When premiums fall, the federal government spends less on premium tax credits. Section 1332 allows those federal savings to return to California as pass-through funding to help pay for the program. Alaska used this approach through the Alaska Reinsurance Program, which covers claims tied to 34 high-cost medical conditions. Federal officials estimate that premiums are 38.5 percent lower than they would have been without the waiver. Reinsurance directly lowers the premium. California will combine it with existing state assistance and savings from the cost reforms throughout this plan to bring down the deductible too. Covered California's Bronze plans now work with HSAs, but California still refuses to recognize the full federal tax benefits of the accounts. Steve will end that state tax penalty. Qualifying plans will also be able to provide a $500 annual wellness contribution when participants complete eligible preventive care or healthy-lifestyle activities. The same Section 1332 waiver will seek approval for simpler coverage options that protect against major medical expenses without forcing Californians to pay for a long list of mandates they do not want. Californians buying their own coverage should have real choices, including a plan that delivers the affordable premium and low deductible promised by the Working Class Healthcare Guarantee. A BETTER WAY FORWARD California does not lack healthcare spending. It lacks a system that treats the patient as the customer. The current system answers to government agencies, insurers, hospital bureaucracies and middlemen. Steve will make it answer to the patient, and focus on delivering a new Working Class Healthcare Guarantee, with affordable premiums and low deductibles for working families. ← Back to all policies

---
snapshot_id: f8ca68d7-0e9d-5a23-9c39-06cde345dea0
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/wait-until-8th-for-smartphones

Saved from https://stevehiltonforgovernor.com/policies/wait-until-8th-for-smartphones (rendered page text, built-in browser, 2026-10-07) POLICY WAIT UNTIL 8TH FOR SMARTPHONES ← POLICY ARCHIVE WAIT UNTIL 8TH FOR SMARTPHONES INTRODUCTION Steve Hilton’s goal is for California to become the world leader in protecting childhood by working towards a voluntary but complete elimination of smartphones for children under 14, in line with the fast-growing “Wait Until 8th” movement which aims to set a social norm that children should not be given smartphones until 8th grade. While there are increasing calls for a complete ban on smartphones - indeed Steve himself floated this idea 11 years ago in his 2015 book ‘More Human’ - a simplistic ban would be neither practical, nor supported by parents and the wider public. THE PROBLEM Smartphones are the scourge of modern childhood. Their vast harms have been well documented, notably by Jonathan Haidt in his recent book ‘The Anxious Generation.’ Children should be connecting and playing with others on a human level, exploring and enjoying the physical world with a sense of fun and adventure, not glued like drones from a dystopian movie to pieces of glass and plastic. Parents instinctively understand this and have been driven to despair by the invasion of toxic technology, wrecking family life, relationships and the simple pleasures of childhood. Not to mention the disastrous impact of smartphones on education and learning. And it is getting worse not better…smartphones, video games, now AI…parents are desperately asking where this is all leading and if it will ever end. Well - the choice is in our hands. With Steve Hilton as governor, parents will no longer be asked to fight this battle one household at a time. Parents who do not want their children to have smartphones feel forced to give in when every other child has one. The companies behind these products know they are addictive and profit from getting children hooked as early as possible. However, current responses to this terrible problem are simply not working. The recent Meta settlement, for example, is a complete waste of time and money. Everyone knows that it will make no real dent in Big Tech addiction and the destruction of childhood caused by the scourge of smartphones. Social media bans, lawsuits, guidelines, exhortations, parental controls will do nothing unless they address the real problem: not the apps but the screens. Specifically, smartphones. Everyone knows that children will find ways to evade measures that aim to manage social media use, just as they are evading Australia's much-hyped social media 'ban' and all the others that have followed. It is time for our society to wake up. We cannot allow children unsupervised access to the internet. It is time to stop the destruction of childhood by focusing on the real problem: smartphones. STEVE’S PLAN WILL MAKE EVERY CALIFORNIA SCHOOL COMPLETELY PHONE-FREE California will adopt a bell to bell ban, strictly enforced. Current state law allows schools merely to limit smartphone use. Steve would require smartphones to be turned off and put away from the first bell to the last, with exceptions only for emergencies, medical needs and disabilities. HELP PARENTS ACT TOGETHER Every class in every school in California will be required to ask all parents to sign a ‘Wait Until 8th’ contract. The default assumption will be participation in the contract; parents will need to proactively opt out. Lists of parents who opt out will be published. A child with a smartphone will be the odd one out. INFORM NEW PARENTS Every maternal and family health provider in California will be required to invite every new parent in California to sign a ‘Wait Until 8th’ pledge. SETTING SOCIAL NORMS IN THE COMMUNITY Any organization receiving funding from the state of California: community groups, after-school clubs, sporting and cultural organizations, faith-based organizations…will be required to commit to a ‘Wait Until 8th’ policy as part of their contract with the state. MAKE BASIC PHONES THE ATTRACTIVE ALTERNATIVE Steve will bring carriers, manufacturers and retailers together to make affordable call-and-text phones widely available and stop pushing full smartphones at young children. Steve will work with the legislature to make knowingly selling smartphones, tablets or other addictive technology to young children a criminal offense. ESTABLISH A CLEAR MINIMUM AGE OF 16 FOR SOCIAL MEDIA Steve will put responsibility on the platforms to keep underage children off their products. This will only work if parents, schools, business and the wider community all move together. The goal is a smartphone-free childhood: a real childhood, to make it normal again for children not to have a toxic, addictive smartphone and to give children time for friends, family, play and the beauty and wonder of the real world. Let’s make California the world leader in making childhood more human. ← Back to all policies

---
snapshot_id: 8f602bbc-f8a2-5e22-beda-050fc0249593
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/abolish-the-dmv

Saved from https://stevehiltonforgovernor.com/policies/abolish-the-dmv (rendered page text, built-in browser, 2026-10-07) POLICY ABOLISH THE DMV ← POLICY ARCHIVE ABOLISH THE DMV A CALIFORDABLE Plan to Cut Vehicle Registration to $73, End DMV Lines, Eliminate Bureaucracy, and Turn Empty Offices Into Opportunity OVERVIEW California is a car state. For most people, a car is how they get to work, get their kids to school, run a business, and live their lives. Yet something as basic as renewing a registration can still mean taking time off work to deal with the hated DMV. California spends $1.46 billion a year on a department with 170 field offices. It is a huge, old-fashioned monopoly that treats the taxpayers who fund it with complete contempt. It is the miserable symbol of California's bloated, costly nanny state bureaucracy, bossing people around while charging a fortune for the privilege. The DMV has trained people to expect delays, confusing paperwork, and bad service. Most states do not have a stand-alone DMV - California is one of only ten or so states with a separate DMV bureaucracy. Of course it is important that the state has secure records, legitimate licenses, and strong fraud prevention. It does not need to make people stand in line all day to receive rude, surly - and insanely slow - service for things that in other countries and states are handled entirely online. Steve Hilton will abolish the DMV, set annual vehicle registration at a flat $73, and give Californians better, cheaper options. THE PROBLEM The DMV is built around the bureaucracy, not the public. If a transaction cannot be completed online, Californians have to fit it into the state's schedule. They take time off work, arrange child care, miss appointments, and hope the person behind the counter can solve the problem that day. If the service is slow, confusing, or unhelpful, there is nowhere else to go. The DMV has a monopoly. For years, Democrats have tried to patch this failure with another website, another kiosk, another appointment system, or a new set of office hours. None of that fixes the basic problem. The public is still expected to work around the government instead of the government working around the public. And California’s basic $73 vehicle registration fee is buried under a value-based vehicle tax, transportation add-ons, and local surcharges. Drivers can end up paying $500, $600…even $1,000 or more, while in most other states, registration is under $100. California already uses kiosks and private partners for some transactions, but the better option can come with an additional fee. People who can afford it sometimes buy their way out of the line. Everyone else is stuck. Other states have shown a better way. Colorado routes most title and registration work through county offices. Arizona allows regulated local providers to handle registrations, titles, driver's licenses, and road tests. California can do the same while keeping the state in charge of security and standards. STEVE HILTON'S PLAN: ABOLISH THE DMV The point is simple: get rid of the DMV bureaucracy and buildings, not the services people need. Steve Hilton's plan keeps the state responsible for secure records and safety, but gives Californians more convenient and affordable ways to get things done. 1. ABOLISH THE DMV AS A STAND-ALONE DEPARTMENT Steve will order a full audit of every DMV function, office, lease, contract, and cost. It will report within three months. He will then send the Legislature a No More DMV Act to eliminate the Department of Motor Vehicles. The state will keep a lean records and safety operation within existing government. Its job will be to maintain the statewide database, issue state credentials, protect personal information, investigate fraud, and enforce safety rules. It will not run a giant network of public waiting rooms. The goal is a much smaller state back-end that does the work only government must do. 2. MAKE DMV SERVICES LOCAL AND CUT REGISTRATION TO $73 Routine title, registration, plate, and renewal transactions will move to county offices and certified local service centers. Californians should be able to handle basic vehicle business where they already live and work, not only at a DMV field office. Steve will restore car registration to what it should have been all along: a flat $73 annual fee for every vehicle. He will strip out the value-based vehicle tax, transportation add-ons, local surcharges, and other stacked charges that turn a basic service into a hidden Car Tax. Registration should cover the cost of administering registrations. It should not be used as a revenue source. Qualified public and private service centers will also be able to handle driver's-license and identification-card transactions, including testing, when they meet state and federal standards. The driver's license or vehicle title will still be state-issued. The difference is that people will no longer have only one government office to rely on. The ordinary registration option must be available for the flat $73 fee. Californians should not have to pay extra just to avoid a DMV line. Local centers may offer clearly labeled premium services, such as after-hours appointments, but the ordinary option must remain affordable. No field office will close until people in that area have an equal or better in-person option. Rural communities will have mobile service where a permanent location is not practical. 3. KEEP THE SYSTEM SECURE AND HOLD PROVIDERS ACCOUNTABLE Every county office and certified service center will connect to one secure state system, use the same identity-verification rules, and follow the same recordkeeping standards. California will continue to meet REAL ID requirements and commercial-driver rules. As separately announced, CDLs will no longer be issued to foreign nationals who don’t speak English. Any organization trusted with a public function must earn that trust. Service centers will face strict requirements for training, background checks, data security, accessibility, record accuracy, and customer service. The state will conduct random audits, investigate fraud, publish performance results, and revoke certification from providers that cut corners or treat people badly. The public should never be trapped with poor service because one government office has a monopoly. 4. TURN UNNEEDED DMV OFFICES INTO OPPORTUNITY Steve will publish an inventory of every DMV lease and state-owned property. Unneeded leases will not be renewed. For suitable state-owned sites, local community colleges, registered apprenticeship programs, and employer partnerships will get the first opportunity to turn former DMV offices into after-school clubs that serve as skills and job-training centers. The focus will be on training that leads directly to work in each community: construction trades, electrical work, HVAC, welding, health-care support, logistics, commercial driving, water and energy infrastructure, and advanced manufacturing. A local operator must be responsible for the program and report real results, including completion, job placement, and wage gains. If there is no practical public use and no credible local training partner, the property should be sold. 5. CUT COSTS AND KEEP REGISTRATION AT $73 California spends $1.46 billion a year on the DMV. That is too much money tied up in an outdated department that gives people a bad experience. Ending unnecessary leases, shrinking the state back office, eliminating redundant overhead, and using competitively selected local service centers will reduce the cost of providing driver and vehicle services. Every contract will be measured against the current cost per transaction. If a provider cannot deliver better service at a lower cost, it will lose the contract. The new state operation will publish its full operating cost, average cost per transaction, and annual savings. Net savings will go first to keeping vehicle costs down, including the $73 flat registration fee. The $73 fee will be exactly that: a fee, not the starting point for another stack of taxes and add-ons. If this reform does not save money and lower what people pay, it is not a reform. Capping vehicle registration at $73 per vehicle per year will reduce revenue from about $11 billion to $2.7 billion. Spending will be reduced proportionately as part of Operation Zero Waste. One essential change: getting better value for money for spending on roads. It is estimated that it costs four times as much to build the exact equivalent section of road in California compared to other states, like Texas - that actually rank higher than California on road quality. CONCLUSION California does not need a better DMV line. It needs no DMV line. Steve Hilton's plan keeps the records secure, keeps safety rules in place, puts registration back to a flat $73, and gets rid of the bureaucracy that wastes people's time and money. Californians should be spending their time getting to work, getting home, and getting ahead, not waiting for the government to let them move on with their day. The DMV is the symbol of California’s bloated, costly and counter-productive nanny state bureaucracy that treats citizens and taxpayers with contempt. The vast majority of states do not have a stand-alone DMV. It is time to put California’s DMV out of its misery. ← Back to all policies

---
snapshot_id: 9685565c-10f5-5664-a14f-c1af02903572
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000

Saved from https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000 (rendered page text, built-in browser, 2026-10-07) POLICY NO STATE INCOME TAX ON YOUR FIRST $150,000 ← POLICY ARCHIVE NO STATE INCOME TAX ON YOUR FIRST $150,000 THE PROBLEM California families are getting squeezed from every direction. Housing costs are out of control. Utility bills keep rising. Groceries cost more. Insurance costs more. Child care, gas, and health insurance continue to get more expensive. For too many Californians, it feels harder every year to get ahead. At the same time, the political establishment keeps asking Californians to pay more while delivering less. The quickest, simplest, and most direct way to put more money in people’s pockets is for the government to take less out. Yet today, California’s government is gouging working families and small businesses with some of the highest taxes in America. California has the highest income tax rate in the nation. The highest statewide sales tax rate. The highest gas tax. Over the last decade, state spending has roughly doubled. Yet the results have gotten worse. California now ranks 50th out of 50 states for opportunity in U.S. News & World Report’s Best States rankings. California has the highest poverty rate in America when cost of living is taken into account. California has one of the highest unemployment rates in the nation. California’s highway system ranks 49th out of 50 states overall, and 50th out of 50 for urban arterial pavement condition. Californians are paying more than ever, yet getting less in return. California’s 9.3% income tax bracket begins at roughly $72,000 of taxable income for married couples. That rate is higher than the top income tax rate in most states. THE HILTON PLAN Under Steve Hilton’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. Millions of Californians would see an immediate tax cut and keep more of their own money for housing, childcare, groceries, retirement savings, or whatever matters most to their families. The result is a tax system that is lower, simpler, and fairer for California families. WHAT IT MEANS FOR YOU For a married couple filing jointly using the standard deduction and assuming an 8% tax rate on income above $150,000: A family earning $150,000 would pay no California state income tax. A family earning $200,000 would save more than $7,000 every year. CAN CALIFORNIA AFFORD IT? Whenever Californians ask for tax relief, the political establishment says there’s no money. Yet California is projected to collect more than $226 billion in General Fund revenue this year. Independent estimates suggest eliminating state income tax on the first $150,000 of income and applying an 8% rate above that threshold would reduce revenues by approximately $40 billion annually. That represents roughly a 17.6% reduction in projected General Fund revenues. The elimination of state income tax on the first $150,000 of income accounts for approximately $20.9 billion of that total, or about 9.2% of projected General Fund revenues. Even after this tax cut, California would still collect roughly $187 billion in General Fund revenue every year. That is about the same amount the state collected in 2020-21. At the start of that period, California had roughly 200,000 more residents than it does today. If California could serve a larger population with roughly the same revenue then, it can do so again today. Californians are not undertaxed. State spending roughly doubled. Housing costs soared. Utility bills rose. Insurance premiums climbed. California became less affordable. And when the political establishment claims there is no room for tax relief, Californians have every reason to be skeptical. During the pandemic, California’s Employment Development Department lost an estimated $50 billion to $55 billion in fraud and improper payments. The State Auditor found that EDD did not take substantive action to strengthen fraud detection until months into the pandemic, paid billions in claims it could not verify, and even paid an estimated $810 million in fraudulent claims filed under the names of incarcerated individuals. California spent nearly $24 billion on homelessness programs over five years. The State Auditor found that state officials could not consistently measure whether the spending actually reduced homelessness. Before asking Californians to pay more, government should prove it can responsibly manage the money it already receives. Californians deserve tax relief. State government should learn to live within a budget that was sufficient just a few years ago. THE BOTTOM LINE Under Steve’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. For millions of families, that means thousands of dollars every year staying in their household budget instead of going to the government. California’s affordability crisis won’t be solved by asking families to pay more. It will be solved by letting them keep more of what they earn. ← Back to all policies

---
snapshot_id: 059c98e5-c21b-5e9d-98d4-07b6dd97d2f4
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la

Saved from https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la (rendered page text, built-in browser, 2026-10-07) POLICY WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA ← POLICY ARCHIVE WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA A world-class pathway to technology entrepreneurship and business leadership THE PROBLEM California has some of the best universities in the world. But for millions of working Californians, the opportunity they represent is increasingly out of reach. We have among the highest poverty and unemployment rates in America. Social mobility in many parts of our state, and for millions of young Californians, seems to have ground to a halt. California used to offer young people opportunity better than anywhere else in the world. Far too many young Californians today feel as if the only option is to be stuck here with no prospect of ever owning a home, or starting a business – or moving to another state. That failure is especially stark in East LA. A teenager in Palo Alto grows up surrounded by founders, engineers, investors, and people who expect them to aim high. A teenager in East LA may have just as much talent and drive, but far less exposure to those industries, those networks, and those expectations. In East Los Angeles, only 11.4 percent of adults over 25 have a bachelor’s degree, and more than 17 percent live in poverty. Too many talented young people are never shown a credible route from where they are to a career in technology or finance, or to starting a high-growth company of their own. There is nothing wrong with building a restaurant, working in music, or joining a family business. Those are part of the strength of East LA. But they should not be the only visible paths. Young people in East LA should see the same horizon as young people growing up around Silicon Valley: technology, venture capital, finance, product development, and high-growth, high reward entrepreneurship. California’s answer has usually been another workforce program. That is not enough. East LA does not need a second-tier program with lower expectations. It needs an elite institution built to recognize talent, raise aspiration, and open doors. HOW WE GOT HERE California has built a two-tier education system. Students from affluent communities get access to elite universities, powerful alumni networks, prestigious internships, and the confidence that comes from being told they can lead. Working-class students are too often steered toward basic job training and told to be “realistic.” Business success depends on more than classroom instruction. It depends on exposure, mentors, relationships, confidence, and access to capital. Young people absorb what is possible from the people and institutions around them. If they never meet a founder, investor, engineer, or executive, those careers can feel as if they belong to someone else. California’s leading universities regularly promise to expand access and serve the communities around them. Some have begun. UCLA Extension has partnered with the SoLa Foundation to offer tuition-free UCLA courses in South Los Angeles. That is a good start. But a collection of short courses is not the same as an elite, aspirational business school with a rigorous curriculum, a respected credential, a powerful network, and a direct path to building and leading a company. STEVE’S PLAN Steve Hilton will launch an elite, locally rooted business school in East Los Angeles through a competitive partnership with one of California’s leading universities. It will be elite in quality, not restricted by wealth. Students will be admitted for their talent, drive, creativity, and potential, and the program will be tuition-free for income-qualified California residents. BRING AN ELITE UNIVERSITY TO EAST LA UCLA, USC, Claremont McKenna and other leading public and private universities will be invited to compete to become the school’s founding academic partner. The selected university will put its name and academic standing behind the school, design the curriculum, provide faculty and visiting instructors, and open its alumni, employer, and industry networks to students. This will not be a satellite office with a famous logo on the wall. Students will earn a respected university credential and transferable academic credit, with a clear path to further study at the partner university, or another equivalently high-status institution. SET ELITE STANDARDS AND FIND OVERLOOKED TALENT The school will recruit aggressively from East LA high schools, community colleges, churches, and community organizations. Admissions will look beyond family connections and narrow measures of academic success to identify initiative, resilience, creativity, leadership, and the determination to build something. The standards will be demanding. Students who need additional preparation will receive it through a summer bridge program, tutoring, and academic support. The answer to unequal opportunity is not a watered-down curriculum. It is giving talented students the support they need to meet an elite standard. TEACH STUDENTS HOW COMPANIES ARE BUILT Students will study entrepreneurship, finance, accounting, marketing, sales, product development, operations, artificial intelligence, data, leadership, and communication. The goal is not to train students for one narrow job. It is to teach them how a company is created, financed, managed, and scaled. Every student will work on a real company, product, or business plan. They will test ideas with customers, build a budget, make a pitch, and learn from success and failure. Students who want to grow an existing family business will be able to use the same tools to take it further. OPEN THE NETWORK California founders, executives, investors, engineers, accountants, and attorneys will serve as mentors and instructors, and every student will receive paid work experience with a technology company, startup, investment firm, or growing California business. The school will also host founders and investors in residence and regular pitch sessions. Students will leave with relationships, references, experience, and people prepared to open doors for them. GIVE STUDENTS THE CHANCE TO BUILD The school will include a business incubator where students and graduates can develop companies with access to workspace, legal and accounting support, market research, and experienced advisers. A privately backed seed fund will give promising student ventures the chance to compete for early investment. Public dollars will support education. Private investors will decide which businesses to back. REMOVE THE PRICE BARRIERS For income-qualified students, support will cover tuition, books, technology, transportation, and childcare. The school will offer a full-time program, flexible options for working students, and a summer academy that introduces local high school students to technology, entrepreneurship, and business leadership before they choose a college or career path. START IN EAST LA AND PROVE IT WORKS Steve will fund the East LA pilot in his first budget by bringing together existing higher education and workforce resources with matching support from the university partner, employers, and philanthropy. There will be no new state bureaucracy, and no new tax. The first class will begin during Steve’s first term. The state will publish results including completion, transfer, paid internships, job placement, starting pay, companies launched, and outside capital raised. If the model works in East LA, California will take it to other working-class communities across the state. A BETTER WAY FORWARD The point is not to train young people in East LA for the jobs others have decided are “realistic” for them. The point is to give them access to the same knowledge, networks, and expectations that have helped create generations of California business leaders. A young person in East LA should grow up believing they can found the next great California company, finance it, build it, and lead it. Talent is already there. This school will match that talent with elite opportunity: from working class to founder class. ← Back to all policies

---
snapshot_id: 36a25a82-1799-5998-897e-958fd9e2119d
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/12-weeks-paid-leave-for-california-families

Saved from https://stevehiltonforgovernor.com/policies/12-weeks-paid-leave-for-california-families (rendered page text, built-in browser, 2026-10-07) POLICY 12 WEEKS PAID LEAVE FOR CALIFORNIA FAMILIES ← POLICY ARCHIVE 12 WEEKS PAID LEAVE FOR CALIFORNIA FAMILIES California gives many new parents the right to take 12 weeks away from work. But the paid benefit stops after eight. For wealthier families, four weeks without a paycheck may be manageable. For working families, it usually is not. Their 12-week right exists only on paper. CLOSE THE FOUR-WEEK GAP Steve Hilton will extend California Paid Family Leave from eight weeks to 12 for eligible parents welcoming a child through birth, adoption or foster placement. The existing wage-replacement rate of roughly 70 to 90 percent will remain unchanged. Birth mothers will continue to receive separate pregnancy disability benefits where eligible. The benefit will be administered through the existing EDD system. Employers will not be required to pay it, there will be no new employer payroll tax, and existing job-protection rules will not be expanded. NO HIGHER TAXES The additional four weeks are expected to cost about $1 billion a year, based on current EDD claims and benefit levels. Workers will not pay for the expansion through higher SDI deductions. The additional benefit will be funded from the General Fund, with matching spending cuts identified in every state budget. California spends more than $251 billion from the General Fund each year. One billion dollars is less than 0.4 percent of that budget. The Legislative Analyst’s Office reports that California recently found $1.2 billion in ongoing operating savings, before counting further savings from vacant positions. Steve will find the money through Operation Zero Waste: by cutting failed and duplicative programs, unnecessary administration, wasteful outside contracts and long-vacant non-frontline positions. The money is there. The question is who Sacramento puts first. Steve will put working families first. ← Back to all policies

---
snapshot_id: b9cb099e-39e3-5a8e-b0ce-8ce49db47461
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/home-help-guarantee-for-new-parents

Saved from https://stevehiltonforgovernor.com/policies/home-help-guarantee-for-new-parents (rendered page text, built-in browser, 2026-10-07) POLICY HELP WHEN YOU BRING A BABY HOME ← POLICY ARCHIVE HELP WHEN YOU BRING A BABY HOME STEVE HILTON’S HOME HELP GUARANTEE FOR NEW PARENTS Having a baby is one of the happiest, most magical moments in a family’s life. But it is also a time when parents can feel most alone, anxious and stressed. That is especially true for families already struggling with the elevated hassles of daily life and the cost of living in California. You bring a new baby home. Now what? Sleeping, feeding, crying…what to do? The rest of life doesn’t stop. Rent is due. Groceries cost more than ever. One parent may be trying to get back to work before the family is truly ready. The baby is not sleeping. You’re constantly worried about feeding, doctor visits, and whether you’re doing any of it right. In the old days your parents or grandparents might have been on hand to help. If you have money, you can buy help. You can hire a night nurse, a lactation consultant, a meal service, or someone to answer every little question. But if you don’t have access to those resources, you’re too often on your own. The richest state in the richest country on earth, at this most vital moment in family life, gives you a website, a phone tree, and a stack of forms. Steve Hilton thinks working parents deserve better than that. A truly personalized, human service. THE PROBLEM California has programs that can help new parents, but they are scattered and hard to find. A family may have to call several different places, tell the same story over and over, and still not know where to turn. That is especially hard when people are exhausted, worried, and trying to keep a new baby healthy. The government knows how to spend money after a family is already in serious trouble, when things have gone wrong. It is much less good at helping avoid problems in the first place. It would save so much taxpayer money, and individual pain and suffering, if we could find a way to do that. Over the years, in many different places, a tried and true solution has been found to work better than any other: a kind, helpful human being. Creating a system where new parents know that if they need help, someone can be there early, with individual, human help or advice - that is exactly what could stop a normal problem from becoming a costly crisis. That’s the insight behind the Home Help Guarantee for new parents. Every new parent in California will have the option to sign up for a Home Help for the first few months after a new baby arrives. Home Helpers will be trained in the basics of post-natal care. They could be current or retired nurses and other health professionals; or they could be grandparents who want to share some of their wisdom. Whatever their background, age or experience, Home Helpers will offer those most fundamental human expressions of support: kindness, empathy and understanding. For those who may be fearful of a “nanny state” - this is the exact opposite. Not exactly a state nanny, but a little bit of Mary Poppins for every California family that wants some help and support. The birth of a child is a critical moment in every family’s life. Steve is absolutely committed to making sure that if they want it, every California family can choose the option of real help from a real person. Someone who can answer practical questions. Someone who knows what services are available nearby, and make those connections. Someone who can help a parent get through a difficult first few months without feeling like they are on their own. WHAT STEVE WILL DO MAKE SUPPORT AVAILABLE WHEN PARENTS NEED IT AND CHOOSE IT Steve’s Home Help Guarantee for new parents will make home visiting, post-natal and early-family support available to every family that chooses it, beginning with working families who do not have the money to buy this kind of help themselves. Support can begin during pregnancy and continue through a child’s earliest days, months and years. It can happen at home, at a clinic, at a community center, or to begin with, even remotely. Parents will be able to choose what works for their family. The goal is simple: when a baby comes home, parents should know exactly where to turn. USE TRUSTED LOCAL PEOPLE AND PLACES The people providing support should come from people and places that families already know and trust: local clinics, hospitals, public-health teams, First 5 organizations, faith-based groups, community organizations, and proven nonprofits. Home Helpers could be current health professionals, retired health professionals, or members of the public - like grandparents - with time, wisdom and kindness to offer, who undergo basic training in post-natal care. California will set the standards and make the funding available. Local people will provide the help and support. California is too big and too diverse for a one-size-fits-all state program. A family in Fresno, a family in Los Angeles, and a family in a small rural town may need help in different ways. FOCUS ON USEFUL HELP The help provided by Home Helpers will be practical. Parents should be able to get support with feeding a baby, safe sleep, early doctor visits, healthy food, and the questions that come with a child’s first years. No lectures. No ideology. No government official showing up to judge people. Just useful help from a kind, caring person who knows what they are talking about. KEEP PARENTS IN CHARGE This program will be voluntary. It will not be a condition of benefits. It will not be a test of whether someone is a good parent. And it will not become a back door for government surveillance. Parents can ask for help, choose the kind of help they want, and stop whenever they want. Their information will be protected and used only to provide the help they asked for. SPEND LESS ON PAPERWORK AND MORE ON FAMILIES California already spends money on maternal health, early childhood, public health, and family support. Steve will start by making it easier for families to access that help and harder for money to disappear into administration. The state should also encourage hospitals, employers, philanthropies, and local institutions to support the Home Help Guarantee. The measure of success is not how many forms get filled out. It is whether parents get help early, babies get a healthier start, and more families stay on their feet. Working parents do not need another program they cannot find. They need someone who can pick up the phone, come by if needed, and help. That is the Home Help Guarantee for new parents. It is designed to help make sure that there is nowhere better on earth to start and raise a family than California. ← Back to all policies

---
snapshot_id: 4f26bc3f-322e-5af0-b34c-c8effcbe6724
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud

Saved from https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD ← POLICY ARCHIVE OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD THE PROBLEM The California State Auditor has warned that weak oversight has opened the door to organized healthcare fraud. Criminals can bill for care that never happened, including by using stolen patient information. Taxpayers lose the money, and the elderly and disabled people these programs are supposed to help can be left without the care they need. Stopping that waste is money the state can save. Steve Hilton and citizen investigator Eric Nissen went to a listed home-health agency in Hollywood and found a locked building, no entry listing for the agency, and a published telephone number that could not be reached. They found those red flags in minutes. State regulators need to check that agency's records and establish whether it has billed taxpayers and whether patients received care. It should not take a citizen knocking on the door to get those questions asked. HOW WE GOT HERE In 2022, the California State Auditor identified signs of large-scale, organized hospice fraud in Los Angeles County. One building in Van Nuys housed more than 150 licensed hospice and home-health agencies, more than the building could hold. The auditor found inadequate checks on licenses and staff credentials, slow investigations, and failures to coordinate between state departments. Those licensing failures sit with the California Department of Public Health. Medicare billing oversight sits with the federal Centers for Medicare & Medicaid Services. The officials who ran those systems owe taxpayers an explanation. Herb Morgan, who is running for State Controller, estimates billions of dollars in potential fraud, waste, and improper payments in Medi-Cal and In-Home Supportive Services, or IHSS. In his white paper, the Medi-Cal figure uses a roughly 10 percent improper-payment band drawn from federal CMS Payment Error Rate Measurement ranges. The IHSS figure uses 12 to 15 percent, reflecting self-reported hours and limited verification. Those are exposure estimates, not a count of proven fraud, and they are the starting point for where to look. California already has provider screening and electronic visit verification. Steve will require the agencies to use those records to check the care being billed and stop fraudulent payments. STEVE'S PLAN On Day One, as part of Operation Zero Waste, Steve will direct the Departments of Health Care Services and Public Health to review high-risk home-health and hospice agencies together. Investigators will check the owners and staff credentials, make unannounced visits to suspect offices, and match billing records to actual patients and services. Agencies must be able to show who delivered the care. When the evidence supports it, the state will suspend Medi-Cal payments, revoke licenses, and refer cases for prosecution. Investigators will trace connected companies so an excluded operator cannot simply reopen under another name, and send evidence of Medicare fraud to federal authorities. For IHSS and home-health visits, Steve will require closer checks of the hours claimed against authorized care and existing visit records. Repeated manual changes, impossible hours, and overlapping claims will trigger review and direct confirmation with the patient or an authorized representative. Live-in caregiver exemptions will be checked in suspicious cases. State agencies will match claims against death records, hospital stays, and excluded-provider lists, blocking clearly invalid claims such as services dated after a patient's death. Families providing genuine care will keep getting paid, with a prompt way to correct errors that could interrupt necessary care. Steve will require additional review before payment for providers with serious billing red flags, then extend those checks to medical transport, equipment, and behavioral-health services. His administration will pursue repayment from fraudulent providers and work with state and federal prosecutors on organized schemes. Medi-Cal health plans will have to account for recovered overpayments, with sustained reductions in improper spending reflected in future payments to plans. Otherwise, taxpayers could keep paying the same amount while the plans pocket the savings. Steve will work with Herb Morgan to check the financial results. When elected Controller, Herb will use the office's independent audit authority to examine high-risk payments and review the savings. He will publish the results under a radical-transparency standard: provider payments, recovery amounts, and exception patterns available to the public, with patient and caregiver identities fully protected. Steve is aiming for $5 billion a year in net savings to California's budget once the changes are in place. Public reports will show the California savings after enforcement costs, with federal savings and one-time recoveries listed separately. Only money California can save every year will be counted as ongoing savings. Within the first 100 days, inspections of suspect agencies and tighter checks on their claims will be underway. Over the following nine months, the administration will strengthen IHSS verification and connect the records needed to catch bad claims before payment. Within 18 months, the controls will extend across the targeted services. Steve will seek any legislation or federal approvals needed to finish the job, and publish the results as the work proceeds. A BETTER WAY FORWARD Families looking for home care should be able to reach the provider and trust that someone will turn up. Taxpayers should be able to see what they are paying for, without seeing anyone's medical record. Steve's administration will make providers and the departments overseeing them answer for that money. Radical transparency will put the financial results in public, and the savings will be reported in public. ← Back to all policies

---
snapshot_id: 667ba687-11cf-563d-b3dd-607609369ded
source_kind: own-site (the person's own site or account)
url: https://goldentogether.com/wp-content/uploads/2024/06/GT_Home-Visiting-3.pdf

Parent Empowerment and Home Visiting: A Human Way to Fight Poverty, Strengthen Families and Improve Life Chances “It is easier to build strong children than to repair broken men.” - Frederick Douglass Prepared by Golden Together, a Movement to Restore the California Dream Foreword “It is easier to build strong children than to repair broken men.” - Frederick Douglass These words, from one of the most influential civil rights leaders in American history, express in simple and evocative terms the premise of our effort in this policy paper. If we can help children avoid the adverse impacts of poverty and insecurity, they will be far more likely to become flourishing and productive members of society. In turn, that means they will be far less likely to require remedial or corrective intervention by the state. So whether our goal is expressed in terms favored by liberals (“a more just society”), or conservatives (“more limited government”), addressing and solving social problems confronting children can move us forward together. Here’s another way of putting it. If we want to sustainably reduce the supply of government - the complex web of agencies, programs, and the spending and taxes that keep it all going - the best thing we can do in the long term is reduce the demand for government, by tackling at source problems like crime, addiction, welfare dependency and educational failure. And so often (as we now know from the latest advances in neuroscience, developmental healthcare and other fields), the source of these and other costly social problems is to be found in the family and especially the early years of life. Indeed, to a much greater extent than is commonly appreciated, the source of many of the social problems we face is to be found in the early days, weeks and months of life. That is the focus of this paper, in which we lay out analysis and a set of recommendations that we hope will command support right across the political spectrum. For California, it represents an opportunity to bring together the best of what has been tried around the world, and the lessons learned, in a globally pioneering program to strengthen families, enhance life chances and abolish generational poverty by empowering every parent, regardless of economic circumstance or family structure, to raise their children in a stable, loving home. In this analysis, breaking the cycle of poverty is not achieved by government bureaucracy but individual humanity: parents learning the specific approaches and techniques that will help their children flourish, supported by trained and trusted coaches who are there for them where it helps the most, in the home. Government’s role is to facilitate rather than provide these human partnerships, ensuring high quality and universal access. These issues were a major priority of my work in the UK government. In 2011 we launched the Troubled Families Program, which was then expanded to include a Health Visitors program. In just a few years the project was estimated to have saved taxpayers $1.8 billion in the form of less involvement by police and social workers, fewer health and housing crisis interventions, and less of the welfare benefit 2 costs associated with high levels of unemployment and ill health. More importantly, these innovations are estimated to have significantly improved the lives and future prospects of over 100,000 people. Of course these programs were not perfect, and I’m not suggesting they be replicated here. But I do believe this overall approach is worth pursuing, and that we have a great opportunity to learn from its successes, as well as its disappointments. And frankly, a new approach is especially overdue in California, where despite our tremendous wealth and success on some measures, we have, shamefully, the highest poverty rate of any state in America. Underpinning the new approach we propose is awareness that poverty and disadvantage in the early years can cause lasting harm. Compared to the general population, children growing up in poverty suffer disproportionate trauma including witnessing or experiencing abuse, neglect, violence, crime, instability, addiction, divorce, malnutrition, homelessness and more. The connection between such Adverse Childhood Experiences (ACEs) and struggles later in life is well established. California’s failure to more effectively fight poverty is harming generations of children and undermining our future. Our modern understanding of the impact of Adverse Childhood Experiences on life outcomes began in the late 1990s through a study conducted by Kaiser Permanente. For three years from 1995 to 1997 over 17,000 Health Maintenance Organization members from Southern California completed surveys regarding their childhood experiences and their current health status and behaviors. The results were striking: Adverse Childhood Experiences were associated with negative health outcomes in later life. The worse childrens’ economic and social conditions, the more likely they were to experience ACEs. While I was working on these issues in 10 Downing Street, I came across the work of Bay Area pediatrician Dr. Nadine Burke Harris, the leading advocate for the recognition of ACEs - what she called “toxic stress” - in public health and other policy interventions. In 2012 Burke-Harris founded the Center for Youth Wellness in San Francisco, a pioneering project to develop “trauma informed health care.” Nadine went on to be appointed California’s first Surgeon General, in which capacity she led the work to incorporate ACEs into a wide range of policy including the California Home Visiting Program which is now active in 34 California counties. This is a great start, but much more could be done. The potential of parent empowerment and home visiting to strengthen families, improve life chances, and fight generational poverty is still in its infancy. As we explain in this paper, we can have a transformational impact on millions of Californians, as well as reducing burdens on government and the taxpayer, with an ambitious new program based on the twin principles of universal access and decentralized delivery. And all in service to that age-old wisdom: prevention is better than cure. 3 For help preparing this paper I would like to thank Jason Bade, my co-author of the book “More Human - Designing a World Where People Come First,” and the California Policy Center’s Edward Ring, who is lead author on this and all of our policy papers. Steve Hilton, Founder, Golden Together California, May 2024 4 Key Points: ● When accounting not only for household income and family composition, but also for available benefits and cost-of-living, California has 13.2 percent of its residents living in poverty, the highest of any state. ● Using a “Real Cost Measure,” a standard developed to measure financial struggles that aren’t included in federal poverty statistics, 34 percent of California households do not earn enough to cover basic living expenses. ● Neighborhoods with high concentrations of poverty have crime rates seven times higher than affluent neighborhoods, and around 30 percent of children in poverty are likely to engage in criminal activity in adulthood. ● Up until age five, a child’s brain has a high degree of so-called neuroplasticity. The brain is still growing and adding cells, and forming its most defining neural pathways. How adults view the world and cope with challenges is largely determined in their first five years of life. ● Compared with the general population, children growing up in poverty are disproportionate victims of Adverse Childhood Experiences (ACEs), including witnessing or experiencing abuse, neglect, violence, crime, instability, addiction, divorce, malnutrition, homelessness and more. ● A groundbreaking Kaiser Permanente study released in 1997 found a direct connection between ACEs experienced in childhood and negative health outcomes later in life. ● Parent empowerment and home visiting programs designed to identify and reduce ACEs have been effective in New York City, San Francisco, the United Kingdom, and elsewhere in the U.S. and California where they have been tried. ● In 2015 UK Communities Secretary Eric Pickles estimated that the nation’s new Health Visitors program had already saved British taxpayers the equivalent of $1.8 billion. ● Home visiting programs in California through the California Department of Public Health’s Nurse-Family Partnership program have limited reach. The total number of children served in fiscal year 2021-22 was just 1,854. ● According to the California Budget and Policy Center, the estimated number of California children eligible for subsidized child care is 2.2 million. It would be reasonable to expect all of these children to be at risk for ACEs, and therefore prime candidates for parent empowerment 5 and home visiting programs that would enhance their life chances as well as saving taxpayer dollars in the long term. ● The key to parent empowerment and home visiting programs is the human connection between a family, and a trusted advisor or coach. These partnerships can therefore be provided in a decentralized manner - not just through existing service agencies but also health clinics, faith organizations, schools and community groups. ● Ensuring universal, voluntary access to high quality parent empowerment and home visiting services has the potential to strengthen families and prevent family breakdown by lending a helping hand at those times when the pressure on relationships is greatest. ● In this way, parent empowerment and home visiting can help reduce overall public spending on lifelong social services by improving the chances for children to grow up to become flourishing and productive adults. 6 Introduction The underlying principle of parent empowerment and home visiting is that if we can reduce instability and trauma in early childhood, especially for children growing up in poverty and experiencing associated Adverse Childhood Experiences (ACEs), that investment will result in a much reduced need for costly government intervention later in life. Done right, home visits by a trained and trusted parent coach will greatly improve a child’s chances of living a flourishing and productive life, instead of repeating the cycle of poverty for another generation. Parent empowerment and home visiting programs can be affiliated with traditional public, charter, parochial, or private schools. They can be delivered by government agencies, churches and other faith-based organizations, nonprofits, hospitals and healthcare clinics or community groups. Home visits can be facilitated according to many differing models and approaches which can compete to see which ones offer the most cost-effective and life affirming results. By using the latest technologies, the time and training of caseworkers can be optimized and accountability can be uniform and timely without requiring a huge oversight bureaucracy. Of great importance is a commitment that participation by parents is voluntary, that access is universal, and a variety of choices will be available from competing programs. It is possible that the innovations that will come out of a diverse portfolio of competing programs will mean aspects of these support programs will appeal to families irrespective of their household income or neighborhood environment. A parent empowerment and home visiting service that offers a coach who can help families improve their parenting skills, or assist with access and advice regarding healthcare, education, counseling, and other vital issues - even managing screen time! - is something that may be useful to any family. We believe a program of parent empowerment and home visiting can command support across the political spectrum by simultaneously advancing goals of a more just society and a smaller government. Investing in childhood success leads to productive adults who are far less likely to be dependent on public assistance or require costly government intervention. We also believe that by adopting the latest technologies, and establishing competing programs with decentralized administration and delivery, we can lower costs while ensuring high quality. Bringing the human connection of trained and trusted parent coaches into the homes of people coping with poverty and trauma can be decisive in helping them to improve their children’s lives and break out of a generational cycle of misfortune. If there is anywhere that an ambitious program of this kind could aim for truly transformational change, it is surely here in California. 7 The Reality of Poverty in California California has the highest poverty rate in America. In a report released by the U.S. Census Bureau in September 2023, when accounting not only for household income and family composition, but also for available benefits and cost-of-living, California had 13.2 percent of its residents living in poverty, the highest of any state. If you add to that percentage those Californians who are living near the poverty line the rate rises to 31.1 percent. A study published in 2023 by United Way corroborates these findings. Using a “Real Cost Measure,” a self-sufficiency standard developed to measure financial struggles that aren’t all accounted for in federal poverty statistics, the study found that 34 percent of California households “do not earn enough to cover their basic living expenses.” With poverty comes trauma. California holds the dubious honor of hosting 49 percent of all unsheltered homeless in the nation. Neighborhoods with high concentrations of poverty have crime rates seven times higher than affluent neighborhoods, and around 30 percent of children in poverty are likely to engage in criminal activity in adulthood. Quoting from a December 2023 summary of poverty and crime statistics: “Young people living in poverty are seven times more likely to harm others or themselves. Incarceration rates in America are four times higher for high school dropouts than for those with further education. People who grow up in impoverished families are twice as likely to have been abused or neglected as children. Over 60 percent of U.S. prison inmates are functionally illiterate, having been victims of societal and cyclical poverty. Household poverty increases the odds of child maltreatment, which can later lead to crime, by nearly 60 percent.” The connection is absolute: Poverty creates trauma, and trauma creates poverty. For children the statistics are unambiguous: they either develop skills to rise out of poverty, or they endure traumas that prevent them from ever achieving upward mobility and their true potential. It is simply not acceptable that in a state with as much overall wealth as California, we tolerate life chances being stunted on the scale we see today. 8 Childhood Trauma & Poverty A concept crucial to developing a new approach to early childhood development is that of Adverse Childhood Experiences, or ACEs. According to the U.S. Centers for Disease Control, ACEs are traumatic events that occur in early childhood, including abuse or neglect, witnessing or experiencing violence in the home or community, or having a family member attempt or die by suicide. ACEs also include “aspects of the child’s environment that can undermine their sense of safety, stability, and bonding,” such as substance abuse, mental health problems, instability due to divorce or separation, or household members being incarcerated. ACEs also arise from malnutrition, homelessness or unstable housing, and other environmental factors. Our modern understanding of the impact of Adverse Childhood Experiences on life outcomes was greatly furthered in the late 1990s through a study conducted by Kaiser Permanente in partnership with the Centers for Disease Control. During nearly three years from 1995 to 1997 “over 17,000 Health Maintenance Organization members from Southern California receiving physical exams completed confidential surveys regarding their childhood experiences and current health status and behaviors.” The findings were unambiguous: the more ACEs experienced in early childhood, the more negative health and well being outcomes experienced in adulthood. The study also found that populations living in adverse social and economic conditions were more likely to experience ACEs. 9 Dr. Nadine Burke Harris, who in 2019 was appointed California’s first Surgeon General, has been a leader in promoting better understanding of the role ACEs - what she also refers to as “toxic stress” - have on the physical and mental health of children and how that carries into their adult lives. As a pediatrician, she has observed how prolonged exposure to trauma and toxic stress affects a child’s immune system, hormones, and developing brain, with potentially permanent impact. The evidence she gathered was based on working in one of California’s most difficult neighborhoods, the Hunter’s Point district of San Francisco When Burke-Harris set up her clinic in 2012, she already knew that being poor is not good for anyone’s health. It’s difficult to eat right; sleep is often disrupted; getting exercise is hard. But even these basic challenges that come with poverty didn’t explain the problems she was seeing among her patients - conditions like asthma, learning disabilities, and behavioral issues - far in excess of what was normal for young children. She began to wonder whether these conditions were somehow connected to the challenging circumstances in which these children lived. What if her patients’ health problems were actually symptoms of something deeper, something more structural in their lives? Answering this question led Burke-Harris to the research conducted by Dr David Williamson and Dr. Robert Anda, the epidemiologists who published the Kaiser Permanente study in 1997. If children are exposed to ACEs, or toxic stress, over a prolonged period of time, the brain adapts to be in a constant state of alert. Stress hormones like cortisol are continuously being pumped into the body. During the first five years of a child’s life, failure to inhibit stress hormones can cause the architecture of their still-developing brain to end up on permanent alert. There is biological evidence that underscores the importance of striving for early childhood stability. Up until the age of five, a child’s brain still has a high degree of so-called neuroplasticity. During early childhood not only is the brain still growing and adding cells, but they are forming their earliest and most defining neural pathways. Which is to say that during the first five years, a human brain is wired in ways that will affect how someone perceives the world and copes with challenges for the rest of their lives. The significance of neuroplasticity in early childhood, the fact that everything children experience in their first years of life is building the foundations of their character for the rest of their life, means that if programs were in place to ensure those foundations are sound, funding that program would yield a tremendous return on investment for society. The concept of ACEs provides a framework upon which to focus these programs and measure their success. But first it is worth contrasting this approach - and the new opportunities it offers - with the past approaches that have failed. 10 What We’re Doing Isn’t Working As it is, even though hundreds of billions of taxpayer dollars have been spent over the last few decades, state funded programs to lift Californians out of poverty have not reversed the trend. In 1980 the poverty rate in California was 10.2 percent. In 2000 it was 12.9 percent. By 2020 it had risen to 13.2 percent, where it remains today. This long-term trend of worsening poverty statistics in California are in spite of massive spending. In the upcoming fiscal year for 2024-25 the proposed state budget, when taking into account all funds, includes $161.1 billion for health care services and $48.6 billion for social services. These are just the two biggest examples of state spending to alleviate some aspect of poverty, but all these programs share a common and fatal flaw. They provide benefits - health care, supplemental food assistance, rent subsidies - but they don’t offer families struggling with poverty, especially families with young children, an opportunity for real transformation. The organizing principle is bureaucracy, not humanity. Because these programs so often lack a personal, human touch, they treat the symptoms of poverty, not its roots. The same may be said of attempts to reduce income inequality. California’s low income working families collect earned income tax credits averaging $6 billion per year. And California has raised its minimum wage to among the highest in the nation at $16 per hour; for fast food workers it is $20 per hour. But again, these programs treat the symptoms. If they worked in any kind of sustainable, long term way, poverty rates in California would be getting better not worse. Parent empowerment and home visiting programs are designed to break free of these failures. But they have never been implemented at the scale necessary to break the multi-generational cycle of poverty. Partly it is because even though politicians and the public are realizing the critical importance of early childhood, that hasn’t yet translated into compelling demand for a change in approach. That reluctance can also be attributed to a widespread skepticism regarding government programs in general, and the daunting cost of creating new programs or expanding existing ones. But today there is a convergence of promising new approaches that haven’t been tried. Either they violated conventional wisdom, threatened entrenched bureaucracies, or the technology wasn’t ready. And the advocates for new approaches may not have made the point strongly enough that investing in early childhood can more than pay for itself by reducing the subsequent lifelong need for public assistance. Parent empowerment through home visiting is the missing piece. That’s why we propose a new and ambitious program, decentralized in delivery but with universal access, to offer parents trained and trusted coaches to offer specific practical help, in the home, with the wide range of challenges involved in raising children. The focus of the program should be to reduce adverse childhood experiences, and while universally available it should be targeted to serve low income families. 11 Successful Programs To Date A pioneer in bringing a more human approach to fighting poverty is David Olds, currently a professor of pediatrics at the University of Colorado. After graduating from Johns Hopkins University in the 1970s, Olds worked at an inner city daycare center with preschool children who had already been emotionally and physically damaged from their parents' struggles. He wanted to help these children and realized that the best chance of giving them a better start in life was to help them even earlier, when they were babies or even before they were born. Olds developed a program that built supportive relationships between trained nurses and at-risk young mothers. Over the next few years, Olds tried this approach and in each case the results were the same: not only were the children's health and lives improved, but their parents' lives as well moved in a more positive direction. In the U.S. the Nurse Family Partnership (NFP) program is now operating in 40 states and since 1996 has served nearly 400,000 families. With a mission to “keep children healthy and improve the lives of moms and babies,” NFP works by having specially trained nurses regularly visit young, first-time moms, starting in pregnancy and continuing until the child reaches the age of two. These new mothers “develop a close relationship with the nurse who becomes a trusted resource they can rely on for advice on everything from safely caring for their child to taking steps to provide a stable, secure future for them both.” But this program, while enormously successful in its own terms, has only reached a small fraction of more than 120 million children born in the U.S. since 1996, or the roughly 15 million during that period who were born into poverty. The California Department of Public Health is one of the 40 states participating in the federal NFP program. California’s Nurse-Family Partnership program primarily relies on federal funding. The program describes itself as “designed for overburdened families who are at risk for Adverse Childhood Experiences (ACEs), including child maltreatment, domestic violence, substance use disorder and mental health related issues. Home visiting gives parents the tools and know-how to independently raise their children. It’s a preventive intervention focused on promoting positive parenting and child development. Home visits by a trained professional during pregnancy and in the first few years of life improves the lives of children and families. Giving children a solid start in their first few years of life increases the opportunity for a brighter, more prosperous future.” But California’s program, just like the federal program it is a part of, has severely limited reach. The total number of children served in fiscal year 2021-22 was just 1,854. To put this in perspective, according to the California Budget and Policy Center, the estimated number of California children eligible for subsidized child care is 2.2 million. It would be reasonable to expect all of these children to be at risk for ACEs, and therefore prime candidates for parent empowerment and home visiting programs that would enhance their life chances as well as saving taxpayer dollars in the long term. 12 An interesting application of a personalized approach to eliminating poverty is the Promise Neighborhoods Institute (PNI), and its centerpiece project and inspiration, the Harlem Children’s Zone. PNI defines itself as “federal place-based initiative striving to turn neighborhoods of concentrated poverty into neighborhoods of opportunity.” With funds from the U.S. Department of Education and matching funds from state and local sources, PNI has launched projects in 38 “Promise Neighborhoods” in 18 states. One of the pioneering organizations that inspired PNI and which has served as a key partner in its national expansion is the Harlem Children’s Zone, founded to “innovate a series of place-based, cradle-to-career services designed to systematically break the cycle of intergenerational poverty.” How the Harlem Children’s Zone began exemplifies the power of individuals committed to the success of children, one child, and one neighborhood at a time. From its origin as a truancy prevention program serving one block in Harlem in 1970, its mission expanded in 1990 when it grew from a safe destination for children after school into an organization offering comprehensive support to children and families. Today the Harlem Children’s Zone encompasses a 97 block area covering Central Harlem and beyond, serving tens of thousands of children and adults, including top-performing charter schools. 13 One service the Harlem Children’s Zone offers is The Baby College, serving parents, caregivers, and children up to the age of 3. Their nine week course for expectant parents, new parents, and caregivers teaches participants the stages of cognitive, emotional and social development for babies and toddlers. Graduates leave the course with parenting knowledge and confidence to successfully navigate “the ins and outs of early childhood development.” Harlem Children’s Zone also offers Early Head Start, a “year-round, home-visiting program for expectant mothers and children ages 0-3.” The home visitors themselves are graduates of an enhanced program at The Baby College, and are led by a point person trained in social work, early childhood education, and healthcare. The Harlem Children’s Zone project incorporates additional programs ranging from preschool all the way through its charter high schools. But it all begins with providing resources including home visits to expectant parents and parents of newborns. In the United Kingdom the Troubled Families Program, its development led by Steve Hilton (as senior advisor to the prime minister), was launched in 2011 and included a Health Visitors program that within four years had served over 100,000 people. In 2015 the UK’s communities secretary Eric Pickles estimated the program had already saved British taxpayers $1.2 billion pounds (about $1.8 billion dollars) on a government investment of 448 million pounds. Quoting from the March 2023 report on the program, which is now renamed the “Supporting Families Program”: “A Troubled Families Outcome Plan (TFOP) set out what each local authority and its partners considered to be the indicators of eligibility and successful outcomes against the program’s six headline problems (crime and antisocial behavior; poor health; domestic violence and abuse; children who need help; poor school attendance and worklessness). On average, families spent an estimated nine months in the TFP. Once progress had been made, a typical ‘step-down’ process involved looking again at a family’s goals, highlighting areas of achievement and areas to improve.” Subsequent evaluations of the UK’s Troubled Families program indicate ongoing returns in the form of savings on social services greatly outweighing program costs. By the 2020s some of these programs were being funded based on a direct connection between reduced social services in the areas covered, a clear demonstration of their success in helping children and families while shrinking government. As previously noted, in the U.S. the Nurse Family Partnership (NFP) program is now operating in 40 states and since 1996 has served nearly 400,000 families by having specially educated nurses regularly visit young, first-time moms, starting in pregnancy and continuing until the child reaches the age of two. The California Department of Public Health is one of the 40 states participating in the federal NFP program. The innovative Center for Youth Wellness in San Francisco, Nadine Burke Harris’s pioneering project, develops trauma informed health care. But all these US-based programs have limited reach. The Nurse Family Partnership has touched over 400,000 families - but that accounts for a fraction of the roughly 15 million children born into poverty in America since the program began in 1996. California’s version of the program reaches an even smaller 14 proportion of families. In 2022 the program served less than 2,000 of the estimated 2.2 million Californian children living in poverty. How can these successful programs be expanded? How can they be structured to actually be self-supporting, if not revenue-generating based on successful outcomes reducing lifelong dependency on government services? What innovations and lessons learned from efforts to date can be leveraged to design a program that will serve all Californian families and young children? In our recommendations we offer some suggestions. 15 Elements of a New Approach One of the most compelling criticisms leveled against government programs to eliminate poverty and childhood trauma is that they grow government bureaucracies and burden taxpayers while often yielding results that are not only ineffective but even counterproductive. The problem with many social programs, so the argument goes, is that the main winners are the administrators that oversee the programs, as they churn out reports and lobby for still more funding whenever the programs fail to deliver desired results. But if early childhood programs could be rendered effective, they would shrink overall government spending. This is the conservative case for programs that focus on early childhood development. The equation is simple enough. By investing in programs that improve the home and school environment for young children, they will be far more likely to grow up as flourishing and productive members of society, therefore saving the state the burden of providing a lifetime of public assistance or intervention. Here are the elements of a new approach to helping children and breaking the multi-generational cycle of poverty: Personal Home Visits At the heart of any new approach to addressing early childhood development and fighting poverty is the presence of one caseworker (or in more human terms, “coach”), who provides a human point of trusted contact with a parent and family. These trained coaches provide practical and emotional support when and where it is needed and appreciated the most - in the home. They become a physically present and reliable part of a family’s life, much like a long term family doctor. They empower parents with the mindset, skills and techniques that will enable them to raise their children in a stable and loving environment that maximizes their potential and their life chances. This is a world away from what families living in poverty in California typically experience today. Instead of a warm, human connection they are generally confronted with dozens of bureaucracies, each addressing some aspect of their lives or “needs.” Interacting with this plethora of agencies, each with its own offices and officials and websites and procedures, with their vast, seemingly capricious and endlessly changing array of application forms and entry requirements, can be bewildering to anyone. For a person coping with poverty and trauma, the complexity becomes a prohibitive deterrent. Instead we propose a person - a human being! - someone who is trained to perform two basic roles. First, and most important, they become a friend and coach to the family, knowledgeable and able to help parents with the basics: nutrition, sleep, hygiene, health, the logistics of getting children off to school in the morning properly prepared, helping them with homework, dealing with pregnancy, infant 16 care, and child care. Second, they can serve as an indispensable guide to help them navigate the labyrinth of agencies and institutions. Many people might assume, wrongly, that much of this is “obvious”, or readily available elsewhere. But this is plain wrong. First of all, social and family fragmentation means that the traditional ways in which humans have passed down parenting knowledge and expertise - grandparent to parent, through the community and so on - have been disrupted. And while it is true that recent years have seen an explosion in the ‘parenting’ market - books, videos, online tutorials and so on - much of this is only accessible to families who can afford to pay for it. But most importantly, the most clear and concise book, the most brilliant online course, can never substitute for the impact of someone actually standing next to you helping you to do it. This is particularly true in homes suffering the disruptive effects of individual or neighborhood poverty and dysfunction. 17 Cultivating a personal relationship puts the human touch in place of the bureaucratic machine. Any new approach that aims to successfully change the landscape of poverty and early childhood trauma must start by restoring this humanity. Flexible Design and Universal Access Parent empowerment and home visiting programs will focus on helping parents, but we recommend a dynamic framework that will ensure multiple program designs are available, differing in order to meet specific priorities of individual parents. Some may focus on helping families develop parenting skills, or cope with sources of trauma and instability, conflict resolution, or finding access to healthcare or quality education, or any combination of these services. Programs will be as narrow or comprehensive as families need, and as we will describe, these programs will have overlapping service areas and compete with each other. Everyone will have access to these programs, and everyone will have several options from which to choose. For example, a family expecting a child could choose a program with a coach who will visit every day during the first two weeks of infancy, weekly for the first two months, monthly for the first two years, and quarterly at least until pre-school. A core principle governing the programs is that they are opt-in and voluntary, while being universally available. There is a stigma that can be associated with accepting benefits offered by government or private charities. By making these programs available to everyone, that stigma is reduced. Decentralized Delivery A decentralized approach can have many aspects, all of which combine to save money while also fostering a more rapid evolution towards best practices. Implementing universal home visits can be initiated through legislation, and can be structured in a way that establishes broad common objectives, but diversifies both the sources of funding and models for implementation. To begin with, the program should be structured so that home helpers can be employed by the government, but also by private for-profit or nonprofit entities. Funding can be made available through vouchers as well as through charitable contributions and in-kind contributions of personnel or resources from private entities. The certification process can also be decentralized by borrowing from the means by which charter schools can earn accreditation in many states: it can be granted by a city, county, or state government, or by an accredited university or state or local board of education. In a 18 similar manner, home helpers can earn certification through review by a variety of credible institutions including those in education, health care, or government social services. By decentralizing the delivery of parent empowerment and home visiting services, this program can avoid the imposition of an expensive new bureaucracy. The primary institution to which parent coaches are affiliated and accountable could be a charter school, or a homeschool network, a church, a charitable nonprofit, a healthcare network or community clinic, or a government agency. Leverage New Technologies The potential of new communications and AI technology to transform and fundamentally improve social programs is vast. Sadly, until now the complexity of bureaucracy has somehow managed to expand even faster than the ability of technology to manage it. That should come as no surprise. But it doesn’t have to be that way. We are one civilizational heartbeat away from having AI programs that really work. Imagine dealing with an AI generated voice that is orders of magnitude more helpful than the maddening voice activated menus that trigger millions of people every day into shouting “let me speak to a human being!” into their phones, usually to no avail. If any place in the world can be first to use AI to solve that problem forever, it’s California. 19 Using AI, or just using the increasingly sophisticated algorithms that are already ubiquitous, can serve as a cost-effective tool to help train potential parent coaches and home visitors. Many of the technical elements of their training can be automated, reducing the need for an expensive training bureaucracy, and freeing up the human trainers to focus on instilling the personal relationship skills so crucial to developing effective home visitors. It is easy to overstate the impact and potential of AI, but nonetheless AI may finally accomplish what technology so far has failed to do, which is shrink government bureaucracy. AI, along with preexisting online resources, is going to make the experience of education, telehealth, nurses assistant, and life training in general far more effective. A family coach will be able to focus on building the human relationship with parents, while relying on technology-driven resources to help evaluate situations and offer useful advice and support. A good example of how AI has the potential to positively impact child development and bring effective resources into every neighborhood is in education. Interactive learning has been around for a long time. Personal computers began appearing in classrooms in the 1980s, and their use rapidly evolved from being platforms for students to learn how to write code to hosting software that offered tutorials on virtually any subject. Interactive learning with presentations followed by test questions, and so-called ‘gamified’ learning where students are incentivized to increase their competencies are examples of primitive AI. These programs, while interactive, operated on pre-established rules and algorithms with predetermined responses depending on student input. Modern generative AI is a paradigm shift. Today it is possible for learning programs to tailor experiences to the individual needs and abilities of young children. An example of a start-up company successfully utilizing the latest advancements in AI to offer educational resources to children is Mentava, whose first suite of products targets K-12 students whose schools no longer offer advanced placement courses. Even without AI technology, educational tools available online are already in widespread use, with excellent products available and tailored to students regardless of age, ability, or income. AI will make these products even more effective and even more individualized. But education is just an example of a sector where digital technology, online access, and now AI are furthest along. It will be possible to use AI systems to cost-effectively evaluate the performance of individual home visitors as well as the performance of the many competitive parent empowerment and home visiting programs. The labor intensive process of correlating critical family outcomes - everything from truancy and educational achievement to every manner of ACEs, employment, family status, etc…using AI all of this can be gathered and compiled with almost no human involvement. We have the tools today to conduct performance assessments without creating a monstrous bureaucracy. 20 Navigating the Transition to Parenthood The birth of a child, while an occasion for joy, is also the beginning of a major disruption to the relationship of the new parents. A 2019 study in the U.K. found that "a third of relationships suffer serious problems in the months following a baby's birth with a fifth ending permanently during the first year." An earlier study conducted by researchers at Texas A&M University and the University of Denver also reported that "parents showed sudden deterioration following birth on observed and self-reported measures of positive and negative aspects of relationship functioning." The challenges that face children later in life because they grew up in a broken home are well documented. Children with divorced parents have lower grades and are twice as likely to not finish high school. Among prison inmates serving long-term sentences, 70 percent grew up in broken homes. Children of single parents are more likely to have mental health issues, they are twice as likely to attempt suicide, and they are more likely later in life to hold low paying jobs. The problem is compounded when new parents are also coping with poverty. It should come as no surprise that divorce rates are directly correlated to income; the lower the household income, the higher the percentage of divorces. The stress that living in poverty places on couples is magnified when children are born. One of the most important ways we can help break the cycle of poverty is to help couples navigate the stress of becoming new parents. There is a huge opportunity here. It’s far too easy, and inaccurate, to suggest that learning how to properly feed a baby, or put a baby to sleep, are skills that can be learned by watching a YouTube video. Within financially secure, stable and intact families, typically these skills are either handed down from grandparents or siblings, or the parents have the time to learn from classes online or offline. But when the household environment is disturbed already by the adversity caused by poverty, the presence of someone offering practical help in your home can make a decisive difference. This distinction becomes obvious when considering how athletes train. There are myriad online resources to teach athletic skills in any imaginable sport, but nobody questions the necessity of human coaches for sports. When a baby is properly fed it will sleep for hours instead of crying all night. Learning how to accomplish this is a skill that young parents learn. By helping new parents acquire this skill, it is possible to tilt the overall experience of being a new parent to one of positive emotions and wellbeing. A baby that is fed and rested projects a contagious happiness. Dr. Alexandra Harrison, a psychologist with the Harvard Medical School, has called these interludes “magic moments,” writing that “Starting in infancy, infant smiles generate activity in the dopamine reward systems of an adult’s brain. Identification with the freedom and creativity of a child in the “magic years” brings pleasure to adults privileged to observe their play.” 21 Home visits to help expectant parents and new parents learn these basic parenting skills can overcome the disruption that comes with a newborn, turning the experience into one that strengthens relationships instead of ending them. The benefits are then felt everywhere, in the enhanced stability of the household itself and the community it is part of, and in the improved prospects for the lives of the babies themselves. 22 Recommendations 1. The Governor of the State of California, in partnership with relevant executive branch agencies, should establish a vision and year-by-year goals for the achievement of universally accessible parent empowerment and home visiting services for every family in California, starting with those at or under the California Poverty Measure (CPM). 2. The first step should be a feasibility and implementation study, including funding estimates and estimates of savings to other government programs as a result of the parent empowerment and home visiting programs at various levels of uptake. 3. Home visiting programs should be licensed under a decentralized system of quality certification, with authorization obtainable from a diverse list of qualified organizations, including cities, counties, state agencies, an accredited university, or state or local board of education. 4. Similarly, home visiting program operation licenses should be available to a diverse range of organizations including new and pre existing ones dedicated to providing home visiting services, or under the management of public school districts, charter schools, parochial schools, private schools, hospitals and health clinics, faith-based organizations, community organizations and government social service agencies. 5. The Governor will specify the broad objectives of parent empowerment and home visiting programs and set specific guidelines for accountability. These criteria will measure the collective progress of each organization against a baseline score assessed for each family prior to commencement of home visits. 6. These standardized measuring criteria will be common to all participating organizations and will constitute the basis for funding and ongoing certification. 7. Private funding of home visiting programs will be incentivized through performance based awards of government matching funds. 8. California parent empowerment and home visiting programs will be required to be universally available. 9. Family participation in home visiting programs will be voluntary. 23 Putting it all Together It is easy to dismiss programs designed to help families, especially when they are government administered. The legacy of failed programs and government bloat that typifies all too many social programs can give rise to cynicism. Much of this is warranted. Many publicly funded social programs have turned out to be mainly beneficial to the bureaucracies that run them, and instead of preventing poverty have perpetuated it. These criticisms, however, ignore the potential for innovation to deliver different and better results. They ignore the fact that while many social programs are dismal failures, others are success stories that can be built upon. And most of all, they ignore the fact that as a society, especially one as wealthy as California, where we boast about being “the world’s fifth largest economy”, we have a moral obligation to address the poverty in our midst that shames us every day. Despite pouring vast resources into the war on poverty, we have been losing. Poverty in California is persistent and growing. Eliminating the spectre of generational poverty is a multifaceted challenge. It involves lowering the cost of housing, as we discuss in depth in our policy paper Universal Housing Affordability. It involves creating economic opportunity for all and lowering the cost of living, the topic of our policy paper on improving California’s Business Climate. But there is something deeper, and in many ways more important. We have to tackle the causes of poverty as well as its symptoms. And as we investigate those causes, we inevitably come to the conclusion that what happens in those early and fragile first days, weeks, months and years of a child’s life can set the course for the rest of their life. Are we content to leave those life chances to chance? To ignore the obvious truth that poverty, whether at the individual or neighborhood level, can make it almost impossible for parents, on their own, to create the kind of environment that will help their children flourish and thrive? Do we ignore the obvious truth that every parent, regardless of economic status or family structure, could do with some help every now and again? That would be an abdication of responsibility and a denial of opportunity. We believe that we can - and now must - craft a vision for universally available parent empowerment and home visiting services that move far beyond traditional government interventions by replacing bureaucracy with humanity. In this way, we can strengthen families, improve life chances, and finally break the cycle of generational poverty that is such a jarring repudiation of the California Dream. 24 25