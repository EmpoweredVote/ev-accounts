You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-fossil-fuels/labels/coder-2.json. Write JSON only, matching
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


## Sources

---
snapshot_id: f846d936-8f96-5f92-9f8a-9f365c4fdd8e
source_kind: news (excerpt only)
url: https://calmatters.org/politics/2026/06/california-governor-primary-hilton-advances/

Republican Steve Hilton advances to November governor's election Nonprofit & Nonpartisan News About Us Newsletters Donate About Newsletters Search Politics Justice Environment Economy Health Housing Education Inequality Digital Democracy Technology Commentary Daily Newsletter Explainers Data & Trackers Programs California Divide CalMatters for Learning Knowledge Hub College Journalism Network Mental Health Reporting Initiative Events Donate Manage your donation Newsletters About Us Impact News and Awards How We’re Funded Republish Our Stories Policies Our Team Jobs Advertise Contact Us Inside the Newsroom CalMatters en Español Videos CalMatters is your nonprofit and nonpartisan newsroom dedicated to explaining how state government impacts our lives. Bluesky Instagram Facebook X TikTok LinkedIn YouTube 2026 Voter Guide Politics Housing Education Economy Immigration Environment California Voices Investigations Impact Events Posted in Politics Election update: Republican Steve Hilton to face Becerra in November by Jeanne Kuang June 9, 2026 June 10, 2026 Republish Share this: Share on X (Opens in new window) …

---
snapshot_id: c83d163f-dce7-5af0-974f-ea3e2b358323
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/6f206fe5-a18b-4af5-b945-c72178d53289

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Race: Gas Prices and Environment (CBS LA) - OTR page: https://ontherecord.empowered.vote/meetings/6f206fe5-a18b-4af5-b945-c72178d53289 - Video: https://www.youtube.com/watch?v=1wbrjc25WP8 - Date on On the Record: 2026-04-06 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [0:12] >> First of all, yes, I'm an environmentalist. How can you not be in California? I mean, it's a defining thing about California is we love our amazing state, our natural beauty, the mountains, the beaches. We all love that and I want to protect that. Um, but here's the big point on this. >> Uh-huh. >> The environment, even green policies, that is not the same as climate and what we now hear being described as the climate agenda. And there's a lot more to environmental policy than carbon dioxide emissions and the climate. And so, when I think about what it means to be an environmentalist, it's protecting our beautiful open spaces. Now, let's talk about climate policy because when you the reason that we have the highest gas prices in the country, higher than Hawaii, in the middle of the Pacific Ocean, which is insane when you think about the fact that we have plentiful oil and gas reserves in California. We're paying higher gas prices than Hawaii. It is the direct result of what the Democrats call their climate agenda. So, let's break it down. Number one, it's the gas tax. People focus on the gas tax. Yes, it's true that it's the highest in the country. It's about 65 cents of every um gallon. But, actually, bigger component of the reason we have higher gas prices here than anywhere else is not the gas tax. It's these climate regulations. The low carbon fuel standard, which forces California providers to import ethanol from Iowa to mix with our own gas. It's insane. The cap and trade system, which is actually a tax, a hidden tax again, on anyone who produces or uses fossil fuels. That massively increases the price. But, But tax, where's that money going? High-speed rail. Which which is obviously a complete disaster, not going anywhere. Then you look at the refinery regulations. It costs more to refine oil and gas here in California cuz you have all these different Yeah, you have a winter blend and summer with complicated regulations. So, refineries are closing down. And then the final component is the attack on our own oil and gas industry in California. So, not that long ago, we used to produce most of the oil and gas that we use in California, here in California, mainly in Kern County where we most of our oil reserves are. Now, most of it is imported. We only produce about 20%. We are importing oil from halfway across the world on giant supertankers spewing out carbon emissions. Guess where our number one provider of oil is today? Used to be California the number one provider. Now, Iraq. How does that make any sense? Their environmental standards are much lower than ours. So, all of these things that are done in the name of climate change are not even delivering those objectives cuz we're actually increasing carbon emissions cuz we're importing all this oil. When we could be using it instead of shipping it on these giant supertankers, we could have been putting it in a nice clean pipeline in Kern County to the refineries on the coast. It's insane. It doesn't make any sense. It's not even meeting their own objectives. So, I would get rid of all of that and we can do that through changes to the regulatory environmental any legislation. You do it through CARB, the California Air Resources Board. You replace the people there and you give them a clear mandate to deliver lower gas prices. And my [3:37] >> Yes, through CARB. And my plan is to repeal the low-carbon fuel standard, to change the way cap and trade taxes are levied, to change the refinery regulations, to open up oil and gas production in California. All of that together, instead of where we've got now, which is $5 gas heading to 6 or even higher. My plan is for $3 gas in California. And I can do that through changes to the regulatory environment without legislation. [4:07] >> Oh, as much as possible. I mean, I I support that industry wholeheartedly. I want you know, we can need a lot of money to beat the Democrat machine. [26:24] >> So, here's

---
snapshot_id: 93bc2f9a-3e8b-50a7-af8e-20ffa6cdfd69
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor's Debate (Nexstar) - OTR page: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e - Video: https://www.youtube.com/watch?v=qRNZ0kuA49k - Date on On the Record: 2026-04-23 - Kind: debate · Governor's Debate (Nexstar) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:15] Everyone can see things have gone off track. Life is impossible. [8:50] We have to make these changes because Californians are being crushed by the gas prices, by the gas tax. We have the highest gas tax in the country for the worst roads in the country. And across the board, we have the highest taxes for the worst results. And you know who's really suffering? It's working Californians. It's small businesses. Most of my career has been in business. I know what it's like to try and run a business. The costs that are being imposed on our businesses and our workers in California is just too much. And one way or another, all the Democrats here are part of this system that obviously isn't working. We need common sense solutions. We need practical solutions. Why are we importing oil from 7 ,500 miles away in Iraq rather than using the oil we have here in California? That's the kind of common sense change that as governor, I will be there to persuade the legislature to do. Because they, in the end, want to help Californians too. [10:05] The first point is that to open up California oil production doesn't need the legislature because it's through executive action. The way that they've been closing it down is through an agency of the executive branch called CalGEM, the California Department of Geologic and Energy Management. I would replace the people in there and give them a clear instruction to issue permits to our oil industry to produce oil here in California so we can cut gas prices for California families and businesses. [14:14] No, we cannot keep going in this direction with Democrats constantly going for their insatiable appetite for more and more taxes for their bottomless money pit, and now the mileage tax, they want to track you everywhere you drive. No, I would veto that. We need to cut spending and cut taxes so that we can give relief to families and businesses. My plan is for $3 gas and your first 100 grand tax free. That's what we need to do to make our state Cal affordable. [22:01] Well, by the way, I'd love to be in your class, Katie. If you get a B for what Gavin Newsom's done on homelessness, my goodness, of course it's an F. It shames our state, the situation with homelessness. We have about 10 % of the US population, around 50 % of the country's homeless population. And as for Javier praising Gavin Newsom for the photo op where he tried to pretend he was cleaning up a homeless encampment, literally, Gavin Newsom did that three times in a row. Nothing changed, and nothing will change if you have one of these Democrats in power. It will be more of the same. My plan is a common sense three -point plan. Number one, it is illegal to live and camp on the streets. We need to enforce the law. Number two, we need to get people into the drug treatment that they need, and it cannot be a choice. Number three, we need to get people the mental health care that they need instead of the barbaric situation we have right now in California as a result of these Democrat policies where the main place where we're treating people with mental health problems is jail. That has to change. [23:14] everything has taken us in the wrong direction. That's why we spend, what is it? The state auditor found $24 billion of our money spent on homelessness. They have no idea where it went because it's going into these nonprofits and crony developers that are, instead of solving the problem, they are profiting of these Democrat policies. Okay, Mr. Hilton, thank you. Your time is up, [33:17] One of the proudest days of my life was the day I became an American citizen. It happened in a ceremony right here in San Francisco. So it is a deep honor for me to be endorsed by the President of the United States and here's the thing that's gonna help every Californian when I'm governor is that we will have a constructive relationship and partnership with the federal government which would be the case, I would hope, for any party in that situation so that we can make things better in California, work with the president and his administration to manage our forests better, to harvest the timber so we can build the single -family homes we need for young families, to work to increase California energy production as he wants to do so we can lower gas prices, to fight the fraud in our government so we can cut spending and cut taxes, to work to enforce our immigration laws in all these areas and more. It will benefit every Californian to have a governor who is a partner on these issues with the president and his team. [36:17] that again, Tom. Wait, no, no. Mr. Hilton. [36:24] putting more money into the system. [42:39] So I've discussed this with someone called Marcus Coleman from Bakersfield. His beautiful daughter, Delilah, was put into a coma by someone driving a truck, an illegal immigrant, didn't speak English, and his daughter now disabled for life. That's what we're dealing with here. It is completely ridiculous that we have people driving on our roads who can't understand road signs and can't speak English. So yes, of course, and I've discussed this with my friend, Sean Duffy, the transportation secretary. We will not be issuing commercial driver licenses when I'm governor to people who are illegally here and who don't speak English. That is obvious common sense. [50:46] I will because we've had 16 years of one party rule by these Democrats. It's given us the highest poverty rate, the highest unemployment rate, the highest cost of living in America. It is obviously desperately time for change in California. It's time for some balance in our system. We have to elect a Republican as governor this year. [54:31] We obviously need change in California. The system is not working. I'm the only one here who has never run for office before. I'm not part of this system. These Democrats can't get it done. Matt Mahan talks about his record in San Jose. Actually, homelessness and crime are going up. Javier Becerra talks about his time in government. He thought it was a good idea to put masks on two -year -olds. We need real change in California. We need to think different. We need to vote different. My plan to make our state Cal -affordable is real and serious, and we can get it done if we just vote differently this year. [59:33] Well, if San Jose is the template for housing affordability in California, God help us, it was just rated the least affordable city for housing in the world. That is completely the wrong answer. The right answer is my plan, which was the first plan that I put forward in this campaign. Number one, we have to end this outrageous hidden tax on housing. They call it impact fees. It can add up to 20 % to the cost of a home. Secondly, we have to reduce the extreme environmental regulations that make it three or four times as expensive to build the exact same home in California as in neighboring states. Number three, we have to end the exploitative union lawsuits that are filed to block housing that extract project labor agreements that make the cost so much higher. And number four, we have to end the war on single -family homes so that we can build the housing we need for young families. We need more starter homes in California. [65:54] It's an absolute scandal that we have just under half of our students can read at grade level for math. It's 35%. Here's the plan. We're gonna learn from what works in other states and around the world. The best way to teach kids to read, phonics. We're gonna have that in every school. The most important thing is that you learn to read by the end of third grade. Just as Mississippi has done, we're gonna make sure, we're gonna give you help over the summer if you can't but if you don't meet the test, you repeat the grade and then you can move forward and we're gonna hold teachers and schools accountable for their performance. [70:09] We have to be clear about why they left. They left because of Democrat policies and wrong -headed regulation. Now, some of those mistakes have been corrected. The ability for insurance companies to price in future risk, the ability of insurance companies to account for reinsurance costs, but we still have wrong regulation and this is the three -point plan that I've announced to fix this absolutely massive problem that is crushing so many families across California. Number one, we've got to get people off the fair plan. It was designed for about 100 ,000 people. Now you've got over 600 ,000. We've got to work proactively to get those people onto commercial insurance. Number two, we have to stick to the regulatory framework that was in the original proposition that set up the insurance department. 60 days to make to approve rate changes. Sometimes now it's over a year. And number three, we have to stop these nuisance lawsuits often filed by private equity from out of state that are increasing the cost of insurance. All right, [75:53] So as the father of two teenage children, I know this issue very well. But actually it's an issue that I've been thinking about and advocating on for many, many years. 11 years ago, in my book, More Human, 2015, that was published, I made the argument that it's not just the apps, it's not just the platforms, it's the screens themselves and that we should set a social norm that children under 16 should not have a smartphone. That is my position now. I think that every parent in their heart knows that it's wrong. Kids do not need smartphones and we shouldn't allow it. [76:38] I think it misses the point, honestly. I think that we've got to get to the heart of the problem and that's the devices and the screens. [82:14] In the middle of it right now is Reacher. One of my sons really enjoys that. Probably more than the rest of us in the family but it's been good fun to watch together.

---
snapshot_id: 5cb5d544-69e6-5a58-9889-c1409a8449f4
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [7:19] the change we need is away from the policies that have brought us to the situation that all the people on this stage described there's a difference though only two of us here actually represent real change away from that like millions of people before me I came to this state in search of a dream like my parents who left communist Hungary to England in search of freedom I was brought up in a working -class immigrant family I made it to Oxford University started a business worked in 10 Downing Street came here in 2012 my wife and my two sons taught at Stanford started a business and now leading the race for governor I want every single one of you to know that I see you I believe in you I won't accept that the California dream is something we talk about in the past tense wherever you want to go I want to clear the barriers away more money in your pocket your first hundred grand tax -free enough with the bureaucracy and the nonsense we will restore the California dream [15:51] I love the way Matt talks about how he's gonna lower costs when his city was recently rated the most expensive the least affordable for housing in the world [16:06] he's not fixing it because he's not fixing it because we're building housing are as high this year as they ever were all the plans he talks about have not actually reduced the cost of housing because fundamentally he supports the policies that have made housing and gas the most expensive in the country we need a change from those policies not more of the same I [22:13] well I don't think it's fair that California taxpayers who can barely afford their own health coverage should be paying for the health care of citizens of other countries and if you look at the record of Javier it's exactly what was just saying that you cannot believe that any change will come from these people he as health secretary dismantled the unit and HHS that was supposed to crack down on fraud billions of dollars of fraud as a result of his rule as HHS secretary and there's another point I think we have to acknowledge we learned today that Javier implicated in this corruption scandal today we learned that he knew about illegal and improper payments from his campaign account to his former chief of staff honestly it pains me to say because I like you personally Javier but you shouldn't be on thanks a lot you shouldn't be in this race you should be preparing your criminal defense [24:32] it Javier [24:34] talk about your chief of staff who said that you knew about these payments let's talk about [27:23] in the polls I think I get [34:30] no instead of forcing housing into places that don't want it we need to build housing in the places that do want it and I'm afraid all this conversation around housing we're not thinking big enough it's all just fiddling around the edges it's a crisis here in California so many young people I see they've given up on the idea that they could ever own their own home we need to build outwards not just upwards with apartment building shoved into suburban neighbors you know that only 6 % of our land is developed in California we could increase that to 7 % and there would be room for 10 million households and single -family homes so that young families could see their kids play outside in California we need to think big again back to the days when we used to build amazing things in California the suburbs of Southern California the state water project we should be thinking about how we store the ambition the abundance of California [41:20] believe a word he's saying his party increased those regulations mr. [47:06] yeah and we need to have common sense on climate change not ideology that ends up being counterproductive and exactly as Chad said hurting every small business and family and everyone in California I'm an environmentalist we love our beautiful natural landscapes our climate here in California we've got to protect that clean air clean water of course that's right but look at some of the things that we're doing in the name of climate change the wildfires that occurred in the Sierras in 2020 because the forests weren't managed properly the co2 emissions from that one year of mega wildfires wiped out all the savings from climate policy in the previous 20 years look at what's going on with our gas prices the highest in the country because instead of getting oil and gas from our own oil production here in California we are shipping it 7 ,500 miles in giant super tankers spewing out carbon emissions in the name of climate we are increasing carbon emissions we need some common sense here [48:55] a [49:54] look I don't know if you know how many EVs are on the roads in California the proportion the idea that that's gonna actually half of the [50:10] number man statewide yeah [50:13] do you know [50:14] it's another percentage of our vehicles on the roads [50:19] 7 % and he wants and it's power our power grid with that it's a lot of batteries this is what you get tell me the math on the batteries thank you you get from ideologues who are not actually it's actually called innovation [50:33] very much how we fix things how to make things work [58:01] Yes. We have to lower gas prices. [58:15] No. [69:28] We need to make it easier for working -class Californians to get into the UC system. As we used to, the costs are so high, the structure of the courses, all of this needs to change. I don't believe in artificial caps and regulation. That's the kind of policy that has got us into this mess. And I have to say, listening to my Democrat friends here, talking about education, it's as if they haven't been in charge for the last 16 years. They are the policies that they support that have got us to a position where less than half the kids in our schools can read at grade level. For math it's 35%. We need new management in this state if we're going to turn things around. We can't have more of the same. We need to make sure we use phonics to teach kids to read. Make sure that they can read by third grade. And like Mississippi does, not go to fourth grade if that doesn't happen. We need to hold teachers accountable also to make sure that we reform the pensions because right now 10 and a quarter percent of every teacher's salary is going towards their pension. We need that to change as well. [73:37] This is not about abortion rights. This is about one state trying to undermine another state's laws. We have a federal system. Yes or no, Mr. Hilton? Sorry? [73:47] Yes, I would follow the law, and that's because we have a constitution in this country that we need to [73:56] abortion rights. Mr. Steyer? It is about abortion. No, it isn't. [73:59] Undermine democracy in another state. Thank you, Mr. Hilton. The people in that state chose differently to California. [74:07] interfere in another state's laws in that way? Mr. [74:12] don't want Louisiana dictating our laws. We shouldn't be dictating Louisiana. Maybe you ought to run for governor. Mr. [74:22] Hell no. [74:56] I'm afraid it's not as simple as that. It really isn't. No, I'm serious. This is exactly the reason we get in. This [75:04] it's not the right way to discuss a very important and serious issue. Do you think there should be more safeguards on AI bots that interact with children? No, I'm sorry. This is why we get into a problem in this country, because we go for these simplistic solutions. Thank you, Mr. Hilton. Mr. Steyer, do you have an answer for me? And it causes problems that are unintended. And we need to have a serious conversation about a very serious issue. We have to protect children, but do it in a sensible way that works. Look at these policies that are being implemented around the world. Okay, Mr. Hilton, I have to move forward. Like in Australia, they don't work. [75:37] It's really not. [75:51] Yes or no questions. They're a little bit longer. Sometimes. [77:08] This state is desperate for change. We cannot have another four years of one -party rule. We need some balance. The only choice for change, apart from myself, is Chad. [80:31] I think we get it, Tom. You're a billionaire. Congratulations. Look, I get on with Tom. I get on with everyone on this stage, and we're all here for the same reason. We love this state, and we want it to be the state that once again offers young people the opportunity to make your life here better than anywhere else in our country. The truth is that we've gone off track. We've got one party rule now for 16 years. The results have been such a disappointment. It is time for some balance. We need some balance in our system. No more one party rule. And the reason that I can make the change happen is precisely because I get on with people from all different backgrounds. I'm not an ideologue. I'm pragmatic. I'm a problem solver. Most of my career has been in business, but I have experience working inside of a government. Above all, I know how to work with people to make change happen. That's what we need in California. Common sense, practical ideas to turn things around and restore the California dream.

---
snapshot_id: c5ad326f-2cd6-589e-a154-2396f20a8ecd
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/3-dollar-gas

Saved from https://stevehiltonforgovernor.com/policies/3-dollar-gas (rendered page text, built-in browser, 2026-10-07) POLICY $3 GAS WITH STEVE HILTON / $8 GAS UNDER THE DEMOCRATS ← POLICY ARCHIVE $3 GAS WITH STEVE HILTON / $8 GAS UNDER THE DEMOCRATS California Democrats have prioritized ‘climate’ ideology over affordability, driving out oil refineries, shutting down cleaner in-state oil production, and piling on extreme, unnecessary regulations. As a result, California drivers pay the highest gas prices in the country (now averaging around $5 a gallon), with experts warning prices could rise as high as $8 a gallon. Steve Hilton’s plan would restore common sense environmental regulation, bringing prices down to around $3 a gallon. BACKGROUND Gas prices in California are the highest in the country, averaging $4.88 per gallon (AAA). They are higher than in Hawaii, in the middle of the Pacific Ocean, even though California has plentiful oil reserves. And they’re heading even higher. According to USC Business Professor Michael Mische, gas could reach $8 per gallon, driven by refinery shutdowns and burdensome regulation. High gas prices are especially painful for working class Californians, who typically have the longest commutes, and for small business. High gas prices are the direct result of Democrat policies in 15 years of one party rule. It doesn't have to be like this. DEMOCRAT POLICIES: $8 GAS Democrats have declared a “war on fossil fuel”, with a stated goal of “net zero” carbon emissions by 2045 - a wildly unrealistic target with an incredibly costly and destructive price tag. Their policies are also chasing refineries out of the state. Valero’s Benicia refinery was crippled by fire. Phillips 66 in L.A. is shutting down. PBF’s Torrance facility is under pressure. Over 25% of California’s refining capacity could be lost in less than a year — a collapse that would cripple fuel access and send prices soaring. And with new California Air Resources Board (CARB) rules potentially adding up to 65 cents per gallon in LCFS costs (Kleinman Center), $8 gas is on the table. STEVE HILTON’S PLAN: $3 GAS California’s current average gas price stands at $4.88 per gallon (AAA California Gas Prices). Here’s how the cost breaks down and how Steve Hilton’s plan could move us towards $3: Eliminate extreme environmental program costs: These add about 54 cents per gallon to gas prices. Removing these programs—including the cap and trade fees tied to gasoline—would immediately cut 54¢. Suspend the Low Carbon Fuel Standard (LCFS), reformulation requirements, and other extreme and unnecessary refinery regulations: These compliance costs add roughly 40 cents per gallon. Cutting these would reduce refinery expenses and thus gas prices by around 40¢. Eliminate the 60 cents per gallon state excise tax: Currently, California charges 60 cents per gallon in excise taxes, which contribute significantly to prices at the pump. Removing this tax would shave another 60¢ off the cost. Additional deregulation measures, including immediate steps to increase California oil production and the suspension of enforcement of SBX1-2 and ABX2-1, could reduce prices even further, by up to 25¢ per gallon. Adding these reductions up: $4.88 (current price) − $0.54 (environmental programs) − $0.40 (LCFS, reformulation, refinery regs) − $0.60 (excise tax) − $0.25 (additional deregulation measures) = $3.09 per gallon ← Back to all policies

---
snapshot_id: 2c625eeb-ceef-53ee-8d3a-f23480dfc587
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/444fa3e9-9466-49b6-a1da-307226c0bbe2

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## The Race for Governor (Commonwealth Club World Affairs of California) - Steve Hilton - OTR page: https://ontherecord.empowered.vote/meetings/444fa3e9-9466-49b6-a1da-307226c0bbe2 - Video: https://www.youtube.com/watch?v=tj1fi4wBAa8 - Date on On the Record: 2026-01-23 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [1:01] So we moved here in 2012. My wife and my two sons, to California. But even before we moved here, I was I want to say I'm in love with California. The idea of California. Everything it represented. There was a time, actually. You mentioned David Cameron is before he became prime minister, and I was working for him. And, developing the kind of policy strategy and, and the ideas that we would take into the new administration. And there was a cover story in the Spectator magazine. The main one of the main political weeklies in the UK. And this and the headline was California Dreaming. This must have been around 2008. And the piece was entirely about, how Steve Hilton, David Cameron's policy guru, the that animating idea behind the vision that he's developing for for the future of the UK is to make the UK more like California. And how inspired I am by California. And so there's something very, very deep within me that loves this state so much. Even before we moved here, moved in 2012, my wife, my two sons, as I mentioned, not necessarily intending to stay, it was really for family reasons. When our second son was born, but we stayed here, we fell in love with it. I taught at Stanford, started a business, raised my family here. And as the years went on, including up to the point where I'm hosting a TV show very unexpectedly, I realized that actually, this state means so much to me. Most of my career has been doing things rather than talking. When you're when you're a TV host, it's an amazing opportunity, but you're just talking. And I really wanted to get back into doing things and making change happen. And as I thought about all of that, I realized my real passion was California. Long before I ever thought about running for governor. I actually started getting engaged in some of the big policy issues that affect our state. And the first one that I focused on was housing. So my first step in this direction was actually to try and put together a ballot initiative to deal with our housing crisis. Now we can get into the weeds on the policy of that, but actually the process of doing that, of trying to get something on the ballot, engaging with the legislature when that didn't happen, it really showed me how broken, frankly, everything is in California, including and probably especially our government. And that's the moment when I thought, you know what? I really want to get involved in trying to make things better and actually fix what's broken about California, especially our state government. [4:03] Well, because there's nowhere better than California. I mean, despite everything, of course, I think we can be a lot better than we are. Otherwise, I wouldn't be doing this. But this is the most amazing place on earth as far as I'm concerned. I have the great joy and privilege now, as part of this job of running for governor, of traveling the whole state. Almost every day I see something or I meet someone that just reminds me how incredible this place is. And I always think, just imagine, how great it would be if we had a good government instead of what we have now. So I there's no question. There's nowhere else I'd rather be. And I want to try and, bring that sentiment to everybody, especially the people who are either leaving or thinking of leaving, because we want people to stay here and build the future in California and make this state the best place to be to to whatever it is you want to do, whether you just want a, you know, simple life, you know, raise your family a home of your own, a nice neighborhood, good school for your kids so they have a better life or something incredible, you know, invent the company that's going to help us live on Mars or whatever it may be, whatever your dream, big, small, whatever, however you define it. I think the whole point of California is that there's nowhere on earth better to do it, and we're not there right now. We have been before, and I want us to be that place again. [5:35] Yes, exactly. And I [6:02] before I get to the politics, I just want to I want to say thank you for the. This is a cup of tea. So, as I've now like to say, hot tea, and, you know, I still have the accent. I'm a proud American. Now, just everyone's clear. Became a citizen in 2021. But there's some habits die hard. So I'm still on the tea. I'm a friend. I very much appreciate everything with milk. I know. I just. Terrible. [6:28] So I think that the truth is that, Without you, I mean, I'm sure we will get, into the actual Partizan politics. But even if you take that out of the equation, it's very clear to people that this state isn't working. I mean, you just listen to my Democrat opponents in the governor's race. None of them are out there saying everything's great. Let's keep going. Not a single one. I was really struck. When I actually, the first time that we had all come together. Not all, but, you know, some of the candidates, it was a forum in, Sacramento, and it was, I don't know, 5 or 6 of the governor candidates. We had Katie Porter, Villaraigosa. Tony, Atkins was still in the race. Alan Keyes was still in the race. I can't remember who else. And we were there talking about the issues and everything. I was really struck, actually, with most of the questions where the Democrats were all making the same critique that I was making about. You had Antonio Villaraigosa started? I remember I it really struck me the very it was a Chamber of Commerce event. So the questions were oriented towards their, you know, business concerns. And the very first question. He stood up. I can picture him doing it. And he went to the front of the stage and said, California has the worst business climate in America. We have to do something about that. And you have a lady like you saying, we are terrible at building housing. We got to do something about that. Katie Porter, it's impossible to raise a family here. It's so expensive. Tony Atkins with the regulations in the state are ridiculous. We all know. And so I think there is broad agreement that things aren't working in California, and that you could put numbers behind that. The Pope, PPC polling and other polls very consistently in the last few years show a very clear majority agreeing with the proposition that California is going in the wrong direction. So the way I put that is that there is a majority for change. There's a majority of Californians know we need change. So that's the starting point. That's why I think this is a good opportunity for a candidate from the from the party that's been out of power because people want to change direction. And so I think that's the real, opportunity I see there is, is just this real hunger for doing things differently. [9:18] meet this [10:02] Both my parents are Hungarian. My stepfather, also Hungarian. I was born in, in the UK, grew up in a very regular working class household, not just very, very normal. Not poverty, not wealth. Just a regular, working class family. But really, I think part of that very familiar story for immigrants of, of that sort of desire for upward mobility, climbing the ladder of opportunity. And that's what I was really picked up, which is we're here now. Your cousins are back in Hungary. I mean, for the first few, you know, I mean, when was this? I was born 69. The Berlin 20, you know, first 20 years of my life, it was a communist country. And we would go back to visit family at least once a year. And all my family would. They're stuck in a communist system where you had no freedom, really. I mean, Hungary was the was better than most. It was not as extreme as some of the communist countries. But you couldn't really do you couldn't stop. It was just a very different world than the one that I was born into, and had that sense of opportunity. And my, my mom in particular said, you got to make the most of it. You know, this is just compared what's happening in Hungary with what's going on here. So, you know, worked hard. My stepfather was was really, you know, my my dad left when I was young. And so I grew up with my mom and my stepfather, also Hungarian. He worked construction. He was a refugee. I mean, his story was the most dramatic. He literally with his brother and some friends from a village. They were in a small village in the western side of Hungary. They heard on the radio in 1956, with the Soviet invasion, the Russians are coming. He tells the story that the Russians are coming, okay, where we're going. And they literally ran for their freight. They ran, you know, they were not far from the border with Austria. They. And it's an amazing story, you know, climbing barbed wire fences and going through minefields. Half of them were killed. These are kids. He was 14 years old. That's the same age as my youngest son. Now, it's an amazing thing to think about. Refugee camp ended up in England and didn't really have much of an education. And so I ended up working construction, did well when I was, you know, growing up, we had a small general contracting business. So my childhood was earning a bit of money working on construction sites. But also I worked hard at school. I got to Oxford University. My first job, though, though, was project manager for a construction company. So I've always had that kind of, you know, real world experience. If you, if you, can put it like that. But I also worked for a little while in politics. I very interested in politics, worked at the conservative Party for a little bit when Margaret Thatcher was still prime minister, worked on a general election campaign. Did that for a few years, worked in advertising, is mentioned all over the world. And then inside, you know, really not understanding business from that point of view. Started my own company in, in England, including a restaurant that's a very tough business for anyone who's, you know, trying to make that work. And then while all that was going on, David Cameron, who had, who I'd got to know very well when we were both working, is really young, you know, kids, in the Conservative Party years before he, he'd gone into politics, got elected to parliament and then a certain point, 2005, decided he was going to run for the leadership of the Conservative Party effectively in the, in the party primary asked me to run his campaign. I did that, he won. Then I by then I'd started my own business, as I mentioned, left that worked with David Cameron. He became prime minister in 2010, went with him into ten Downing Street. I was senior advisor. I had my little office, next to the cabinet room and really encountered for the first time directly the how hard it is to make change happen in government. And that experience, which I always look back on, not necessarily as having been fantastically successful in what we try to do. In many ways the opposite, very frustrating. But it does show you it really taught me how hard it is and how you know what it takes to actually implement change in in government. And then as I mentioned, in 2012, we moved here. I mean, just what happened? I was taught at Stanford for a couple of years. Got the bug there for tag. I did a start up, did that for a few as founder and CEO of a startup, and then, very unexpectedly, along the way, wrote a few books along the way. And, and then very unexpectedly got the offer to host a TV show, which really was nothing I'd ever contemplated doing. [14:52] I if you. [14:56] probably not the [14:59] I think the I can't remember exactly, but I think that the actual, the way that happened was that I was in the UK, I wrote a book in 2015, which I think still is the one I'm really, you know, I feel very, you know, it's the it's the sort of broadest expression of, of how I think about the world. A book called More Human Designing a World where people come first. And that theme of the book was the decentralization of power, that things, the modern world has become too big and bureaucratic and centralized, and we need to put things back to a more human scale. And that it came out in 2015. There was a paper back in 2016, which I updated with my position on Brexit. So that was what was going on in 2016. I went back to do the book tour and as it were, it came out in favor of Brexit as, to me, a perfect example of the argument in the book against centralized power. Now, that was pretty controversial because David Cameron, who is a close friend and who I'd worked very closely with, was on the other side of that argument. And it got, you know, I did a few TV appearances. I think that's how I came to the attention of the powers that be at Fox, and that's where it came from. [16:37] Yeah. Gloria Romero. So Gloria and I got to know each other a few years ago when she was working on a ballot initiative for California, for school choice. And Gloria was the state senate leader for the Democrats. So, you know, a big figure in California politics. Very that's a really big role. And she was always, I mean, as she would say, someone who really understood and appreciated working bipartisan. And so that was where she was coming from, trying to make things happen. And that was back in the days when she was there, the there wasn't a supermajority. And you had to work with Republicans to get certain things done. And so she was someone who I've known for. She is someone who I've known for years now. When I started my policy organization, Golden Together, that was really the first step towards this. As I mentioned, housing. And then we worked worked on other issues. Gloria was there with me on that. We've worked together on education policy. But the thing is that, it's true that normally in the in this race for governor, it's and it's literally true that everyone is for the statewide offices elected independently. So it's not like a formal ticket, at the presidential level, for example, where you vote for one and you get both, you have you're going to have to vote for me and Gloria. But actually, it's broader than that because I've always seen this effort to turn around California as a team effort. And I guess that goes back a little bit to my experience in the UK cabinet government. I've seen how that works. It's not just one person. I mean, the Prime minister in the UK system is considered, you know, primas into Paris in the Latin, the first among equals. And it's a team. And it's true. I mean, I've started companies everything that you can't do anything without a good team. And that's why I always saw this race and, my role in it as putting together and leading a team of credible, serious people across the board so that, yes, that's Gloria for lieutenant governor. She's got a ton of experience. I'm an outsider running for governor. She's got a lot of experience in Sacramento. I think that's a good compliment. But broader than that. Last week we announced, as part of what we're calling the golden ticket, for California. Michael Gates, who's running for attorney general. I was there with Gloria to support his launch. Herb Morgan, who's running for state comptroller, very well qualified candidate for that job. We've been working together for months now on on the question of fraud and cutting waste in our state government spending. So that's four of us. And there'll be more. You know, I really see this as a team approach. [19:32] quite. I mean, but let's get into that. But there's a lot you can do without the legislature, of course. So it'd be good to work with the legislature. [19:51] Well, I mean, okay. But for me, the the strongest direct role you can have is through how you run the executive branch, in particular the hundreds of agencies where a lot of the things that are making it so impossible and expensive to do anything in California that's coming through these agencies where you have thousands of appointments and you can direct their work, you know, the Air Resources Board, the Coastal Commission, the state water resources control it, you know, and endless agencies. So that, to me is my focus in terms of what I can actually get done. [20:59] Oh for sure. No, no, no, definitely I'll be the Republican candidate in the top two, I'm sure of that. And the the party endorsement is obviously would be greatly appreciated. But it's not the only thing that matters in this race. [21:20] It does to a certain extent, but I don't know how much, honestly. And I think that it's it's, as I say, always welcome, as is the endorsement of county parties. That process is happening right now. It's, you know, I'm very used to that. I spent the last three years, four years traveling the state, meeting people, including at the local level within the Republican Party structure. And I've enjoyed that greatly. [21:55] Correct. The [22:02] candidates [22:05] seen each other a few times. I have a perfectly cordial relationship. Yeah. [22:14] argument that I make on my on my part and I've tried to avoid being negative about, about other Republicans and my, my, I, as I say, the there's plenty of people out there doing that without me adding to it. I make the positive case, which is that I've got a long track record of business experience, government reform experience, being out there campaigning, a broad policy expertise. I mean, those years of work, not just back in the day when I was, you know, working inside of a government at a very high level, but actually here in California, I mean, my those years where I've been traveling the state, meeting people, learning about the issues and developing policy solutions have really provided the foundation for this. So if you go to obviously there's a campaign website which is, you know, mainly focused on the ways that people can get involved and so on. But my policy organization called and together you go to the the policy section there, you'll see very detailed policy reports written by me on, all the big issues on energy, water, the business, climate, crime, education, you know, the, the there's, there's, a body of work there that really reflects the very high level of preparation I've put in to deal with these policy problems across the board. And I think that's really I would say, I would argue is that is why I'm the best qualified not only to win, but actually to do a good job once I've won. [24:09] Yeah, I'm. afraid I pay attention to the numbers. Very, very detailed race, as I always say. You know, I've started businesses, and you can't do anything without your investors. And this is this is the same. And it's like building a startup. You know, I've never run for office before, so I don't have a base of donors to go to, like my, other opponents. In fact, all of the I think I'm right in saying every single one of the serious candidates has run for office before. And so I had to start from scratch in a way that they didn't, the for the governor's race, it goes in periods of six months and, it goes up to the last period we're in ended December at the end of the year. And then everyone has to report their numbers by the end of January. So there's some people that haven't yet. Most of us have and cumulative. Lee, I think I'm kind of, I don't know, top in the top 2 or 3, but for the six. But it's growing. I mean, we're moving in the right direction. So for the last six month period, I remember I launched my campaign at the end of April. So we didn't have the whole of the first phase. So we've been in the race for less time than most of the other candidates. But for I do know the numbers for the second six month fair. So Antonio, very close to 2 million. Have you Bacerra 2.7 million. Katie Porter 3 million. Eric Swalwell 3 million. I was 4.1. So quite a long way ahead of the others, actually. [25:43] Yeah. I mean, we've got, a really big, broad base. That's one of the most exciting things about it, having, you know, these people who've run for office before, as I mentioned, we haven't done that. But the number of unique donors we have, which is something people look at, because that's really an indication of the breadth of your support and the grassroots support. You have 30,000 plus, which is a high number. I mean, if you look at Gavin Newsom and his donation record for the, the prop for the prop 50 campaign just now, I believe he had about about 100,000, something like that for that campaign he's been in. He's been running for office all his life. So that 30,000 number is a good number. [27:18] You're right. And I think the probably the most interesting thing about the polling is that the largest number is for don't know. Yeah. So 30 something. Exactly. So it's early in one sense. It's not early in another sense. I mean, we've getting to the point where, I think it'll be very clear who's going to make it through. I think that that's why I've been [27:37] very, I know my job is to campaign to, to to be that leading candidate. And that's what I'm doing. And I've, we've, we've we turned up the volume this year in terms of the campaigning. I was out there that two weeks ago with, analysis of. So going back a step forward, a step back, this issue of fraud is a huge issue for a lot of people because it's all come to light through the Minnesota scandal. I remember at the time saying when that really burst onto the scene in said around Thanksgiving last year, look how bad the fraud is in, in in Tim Walz in Minnesota. You can bet that it's a thousand times worse in Gavin Newsom's California. And I because of the just the fact that we've had so many years of one party rule now, 16 years of one party rule, which inevitably means you just get less accountability and challenge and and so on. And it breeds that kind of complacency and corruption and so on. And and then we started putting numbers on it. So the guy I mentioned, Herb Morgan, who's running for state comptroller, he and I teamed up, we put out there a, you know, just with the resources we have in our campaigns. Very simple website. Carly fraud.com to try and try and get tips whistle blows. That was a big part of the Minnesota story. We got hundreds of tips which you've been looking into following up. And then early the first Monday back after the holidays, we put out our estimate of the total. Looking at those tips, the direction that that helped us identify potential areas for fraud, the size of those budgets and so on, and the published fraud numbers that we've already got for 24 all or missing in, budgets that can't be accounted for, homelessness, 24 billion, employment department, 55 billion during the lockdowns, etc. our number was $250 billion. Our lower low end estimate. And it's actually going up the whole time. That's an example of how this year we are really out there campaigning more directly, more strongly yesterday, you know, that would include the announcements of Gloria or Michael Gates and the Golden Ticket last week. This week we're really focusing and it's the beginning of a campaign on the really the key issue, I think, for everyone in California, which is affordability. Yesterday and today we again, we've done a calculation how much more expensive it is to live in California as a direct result of Democrat policies. We just took a very simple calculation. The average cost for all the components of of someone's typical budget. So rent, utilities, gas, groceries and so on. Health care insurance. And we just took the national average for those items and the California average and did a very basic calculation. And here's the number $35,000 more in California, $35,000 published that yesterday. It's actually 34,000 a year. Yeah. Are you. [30:39] Well, extra. That's not the that's the addition. That's that's the surcharge. Well and. There's the San Francisco number which. Is well for everyone. It's different. And so we also published an online calculator. I'm sure you enjoy doing the numbers where you can plug in your own costs and see how much more you're paying for Democrat policies. It's called California Dem tax.com if you're interested. We'll be promoting that again today. But I'm just giving these as an examples of how we're stepping up the pace, raising the volume, and really going to be out there campaigning to do exactly what you said, which is to be the dominant candidate. Certainly on our side of the political fence. [32:05] Well, let's start with the number of people who want a change of direction, the 60, 65%. Well, some. Think it should [32:14] don't. Know about that. You don't [32:18] actually, I don't I think that's about to I there are some people who think that, but it's a very tiny minority. So I think that's the starting point. It's also, yes, registration. You could look at that number, but in the end, that's not how people vote. So a lot it's a big proportion. It used to be the Repub for a while Republican registration was number three. Democrat then declined to, you know, no party preference. And then [32:44] Republicans that's flipped recently Republican registration has been increasing. Democrat registration has been, stagnant. And so it's moving in the right direction for Republicans. But the real point is actually not registration isn't what matters. It's voting. And if you look at the voting numbers, there's been a very there's a there's a basic thing that I think is often overlooked, which is that it is a more Republican state than people think. So when you listen to the commentary sometimes and you'd think it was like an 1820 state, it's really not, the average vote share, I think, for Republican statewide candidates in the last 20 years or so is around 41%. So let's just call it 40%. That's that's a baseline that is higher than a lot of people realize. And of course, it's a big gap. I'm not I've always said this is not going to be easy to win, but it's not impossible. And then the other thing I want to look at when you talk about turnout, I did it just quick back of the envelope calculation, as is often done to try and estimate the turnout at a midterm election this year. And you typically have a lower turnout. But and if you do that and you try and usually you take the average of the last two to get an estimate of what the turnout will be. If you do that, the number, the the projected total number of votes this year in the general election in November is actually 11.7 million. So it's very close to your number. The target to win just over 50% is 5.9 million. That's the number that's in my head. 5.9 million. And then you look at voting in the presidential year last year, how many people voted for President Trump in California without the president even campaigning here? 6.1 million. How many voted for Steve Garvey for Senate? 6.3 million. In other words, when people say you can't win because there aren't enough Republican votes, it's literally not true. There are enough Republican votes. You've got to get them to vote in a midterm election for the governor's race. And there are things you can do to effect that with your campaign, your ground game, all those things that we're working on. And there's another really important factor this year, which is and you mentioned call to me a couple of times, calls a good friend of mine, we've been working together, but he's really been in the lead, along with some others on voter I.D., the ballot initiative on voter ID, which is now pretty much certain to be on the ballot in November. That is a very, very big turnout machine for Republicans, because they really care about their Republican voters. And so I think that things are lining up to, to point is in a direction where we have got the chance to turn out the number of votes we need. Of course, it's true that that's not that you got to do more than that. And I think that this is the second thing I'd say on this, which is the nature of my campaign, the way I'm going about this, and you can see it from the platform that I've put out there. And so it's positive, practical things, pragmatic things to help people in their daily life, working families, small businesses. It's not ideological. It's not divisive. It's all, you know, what are the key things I'm talking about in this campaign? Cutting gas prices $3. Gas, electric bills. Cut your bills in half a home. You can afford to buy your first 100 grand free of state income tax. These are very practical things that I think everyone can get behind. [36:59] First of all, I thought I think prop 50 was I mean, I totally disagree to try to stop it. It's unconstitutional and so on, and made those arguments in court. We ran into a very Partizan judge, so that didn't go anywhere. So I don't want to get into prop 50 other than to say it, it it's very distant from those everyday practical concerns. That's why I think you had a low turnout across the board. It was a low turnout because it's just for regular people who are working incredibly hard, often 2 or 3 jobs to make ends meet because everything's so expensive in California. It's such a distant thing. Something about districts. What are you talking about? It was it was very, you know, distant from their daily experience, whereas this race is very directly related to their daily experience. And of course, that would be my job in the campaign to make that clear. And you can predict exactly as you've done exactly how this campaign is going to go. Well, it's me against whichever Democrat gets into the top two. They will be making the entire thing about Trump, and I will be trying to make the whole thing about California. And that's the battle in the campaign. [38:40] Well, look, the my focus is California, and I think that's really going to stick to that in the campaign, which is that I'm running for governor of California. Here are my plans to make life better here. One of the things I think that will be helpful as governor is that I do have a relationship with the president, and half the cabinet are friends. I think that it's helpful to have someone here in California has a good relationship with, at least for the first two years of the governor's term. It will be a, Republican administration led by President Trump. I think it's going to be helpful. It means that I'll be able to get a better deal for California. So I think that's an argument that you can put against the, how the Democrats will want to characterize it. And I think that beyond that, one of the things that is really, you know, why if you go back to when when Donald Trump, as he then was first came on the scene, the thing that was interesting to me, I just finished writing that book human. [39:40] 2015 and then doing the US version, the US edition, which is like, you know, changing the stories on the data and so on to make it, focus on the US and those and that book is structured in terms of broad issues. So, like, poverty, inequality, food, health, education. And one of the things that I, really took absolutely brought me up short and a very much determined to a certain extent, my orientation politically from then on was this chart, which I think is now become pretty well known, because I was just trying to update data from the UK edition, and this showed the earnings of the majority of American workers. I think the technical economics term is that non managerial, non supervisory workers, it's about 80% of the workforce. And it plotted the earnings since you know for the last few decades, the last half century actually on a chart along with corporate earnings and the earnings of the everyone else the top 20%. So we hear about the top 1%. It's not really that it's the top 20%. That's where the real differences and it's an absolutely stunning chart where basically you've got a hockey stick for corporate earnings, a hockey stick for the top 20%, absolutely flat for the majority, for 80% of American workers. If I'm right, I think the it's since I think 1974 it's amazing after inflation. So basically you've had total stagnation for the majority of workers since the mid 1970s, whether whatever administrations have come and gone, globalization, this stuff totally flat. And I think that really explains so much about what's been going on, what we now think of as the populist movement both on left and right, Bernie Sanders and, President Trump as it was in 2015. They both came up together. Brexit, all of these things. And so the argument I always made make and still make is that Donald Trump was the first Republican to really understand that, actually, and to understand that the majority of American workers have been losing out. And that's the broad basis on which I, identified with him and the arguments he was making. And particularly in that election, I thought, actually, Hillary Clinton doesn't get that. She doesn't. And now people talk about the and all the things he's talked about China, immigration, the role of low wage immigration, who is making that argument about open doors, open borders in 2015 and 2016, Trump and Bernie Sanders together. Bernie Sanders was making the argument for closing the border because because the competition from, cheap low wage immigration, low wage immigration. So I think that's the real driver for me. And I think that remains true. And one thing I would finally say on that is that what you saw and that changed that pattern changed in the first Trump administration up to the pandemic. But for the first time in decades, the earnings of the lowest 20% rose faster than the earnings of the people at the top is a really big change, and I'm optimistic that some of the economic policies that have been put in place last year will have that. And the energy, deregulation, all these things coming together that I think we'll see another boost in economic, result, the positive economic results, especially for working people. So I think we don't by November, but September, October, you know, election time, I think it could be a very different story about, this second Trump administration in terms of the economic impact. [43:48] what right. And I think that the point is that I look, here's another way of looking at it. Gas prices. So we have the highest gas prices in the country, particularly hurts working class Californians who are driving their cars in their trucks. You often hours a day to get to. It does not affect, as I sometimes put it, the Marin County climate worries and that sort of work from home tapping away at their MacBooks right. They're not affected by gas prices. It's working class people who are, we have the highest gas prices in the country, high even than Hawaii in the middle of the Pacific Ocean, even though we have abundant, oil and gas reserves here in California, we there are 40 states now. I my my plan is to get to $3 gas. We have five, six, seven, $8 that there are 40 states in America where it's $3 or below. President Trump is the president in all of those, we have the highest unemployment rate in the country. President Trump is also president, where we have the lowest unemployment rate. We have the highest poverty rate in the country. The president President Trump, is also the president in the states with much lower unemployment. And so there's something to blaming everything on Trump is obviously ridiculous. Now, I know they'll try and do it because they've got nothing else, because 16 years of one party rule by the Democrats have produced total failure on every front. So what else can they do except blame Trump? But if you just think about it for a moment, it's obviously ridiculous. [45:52] bargaining. [46:16] but just to be clear, I don't have a plan, right now for, ending collective bargaining or anything like that, because it's not as simple as just saying, I'd like to do that. What I, what I have done is repeatedly cite and quote, former Democrat Titanic figures in the Democratic Party, starting with, FDR, who argued that the whole concept of government unions is a unconstitutional and b morally wrong, where you have people who are basically on both sides of the negotiating table. When it comes to, bargaining for things that are funded by the taxpayer. And of course, you see the impact most clearly in the devastating results in our public school system, which is so strongly controlled by the teacher unions, that have turned into something that is all about protecting their members rather than promoting education for students. So I just think that I just got to tell the truth about what's happening, by the way, with Quick Story, when when I was working on housing, I remember having a meeting with in the Ledge with a member of the legislature and talking about my plan, and they said, oh, this is fantastic. We transformational. And I said, great, let's work on it together, you know, bipartisan. And they said, well, I couldn't support you publicly. I said, why not? So, well, the unions would hate it. And we were sitting in I remember the office above Sacramento, you could see the capital and this is. Yeah. So they'd hate it. Yeah. Well, they just wave the arm like this. The unions run this place. That's an elected member of the legislature saying, now that's outrageous. only [49:13] Well, I mean. That's what's wrong with the system. I mean the top two system was intended, to promote moderate moderation in our politics. I mean, everything's gone so far left since then. It's completely failed. The top two system, I just think is a joke and should be, we should move away from it. I can't get into those kinds of cynical games. I mean, what am I going to do about it? Be the dominant Republicans so they can do whatever they want with with their, cynical campaigning? It won't work because I'm clearly the leading Republican and the in the, in the situation that you described with God, he was the only one really. [50:02] very happy about the top tier system either. [50:10] want. I'm very confident that I'm going to be the Republican in the top two, and that I will eventually win in November, because the state needs change. Everyone knows that. And how can the people who got us into this mess be the ones to get us out of it? [50:45] Yeah. Are you [50:48] definitely. You know, the bills are so high. You know, one of my, you know, very specific, policy plans is cut your electric bills in half. But remember that a lot of what they do is directed by Democrat policy. So the fact that, for example, they haven't been investing what they should have been doing in fire prevention and clearing brush from near the lines and undergrounding and all the rest of it. Why? Because the governor and the machine in Sacramento has been focused on EV charging stations and all that. You know, the climate crusade. And so I think that they've been in the position of being this, you know, being pushed around and having to there was a very funny line in, Tina Brown's Substack, if you know Tina Brown, she's the former editor of The New Yorker, Vanity Fair, and she, and she wrote this. You just I just read it last night. She talked about Davos and Greenland and Trump and all that, and she had and she had this wonderful line about all the CEOs in Davos who are relieved that they no longer have to pretend to care about climate change. And it was like, and I think that that's the in a sense, the PGA are just a just a creature of this absolutely unbalanced and extreme, climate crusade led by Tom Steyer, who's one of my other opponents. So I think that once they're freed from that PGA, they can get back to what they should be doing, which is providing all of us with affordable, reliable electricity. [52:34] Yeah, I was there for the, one year anniversary. I spoke at the event, where Spencer Pratt announced his, bid for la mer. I mean, it was just shocking to see that's a that is not a Republican. Community at Pacific Palisades. And it was very much a community event. I spoke towards the end. I listened for 2.5 hours, and the rage that they still feel. I mean, it's a year on the the name of that event was called They Let Us Burn. That was what was on the backdrop. They let us burn. I mean, that is an intense sentiment and that's how they feel. And by the way, who's the day Gavin Newsom, Karen Bass it's very simple. We and because we used to this is not none of this complicated. This is what we used to do is common sense. People remember it. You clear the brush. I mean, there in the in the Palisades and in that area, responsible residents who are trying to clear the brush from their property were fined by the Santa Monica mountain Conservancy and other state agencies. They were fined the the the, the, same organization was they were trying to replace wooden, poles with metal ones would be more fire resistance. They were stopped for conservancy reasons because they were trying to protect a plant, the milk vetch. mean, I the it's extreme environmentalism gone mad. All you actually have to do is get back to common sense, which we've done for centuries, which is you manage the fuel load, whether that's in the Sierras, with the forestry, by the way. Then you can re revive our timber industry in California, which used to be a huge part of our economy, particularly rural economy. It's not that long ago we would take around 6 billion board feet. That's the measurement of timber out of our forests. We use it to build houses. Now it's one and a half. It's fallen to a quarter of what it was. We're using more timber. Where's it coming from? Oregon and Canada being trucked in further, more carbon emissions. The forests are overgrown, lumber costs are higher. It's insane. All of this is insane. And so it's actually common sense that we, you know, allow timber to be harvested from our forests. That reduces fire risk, creates jobs and opportunity in those areas. Cheaper construction materials, lower carbon emissions because you're not transporting it. So far. Like it's not complicated. And [55:11] right.

---
snapshot_id: e06dd6d5-8cb3-5654-8038-01fb70d54308
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/38e71313-bdc5-4104-8e9c-9e5d73d23f08

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## BECERRA vs. HILTON on Gas Prices (CBS LA) - CA Governor Candidates In Depth - OTR page: https://ontherecord.empowered.vote/meetings/38e71313-bdc5-4104-8e9c-9e5d73d23f08 - Video: https://www.youtube.com/watch?v=Wpt8MSuSe5Y - Date on On the Record: 2026-10-01 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [3:50] >> First of all, yes, I'm an environmentalist. How can you not be in California? I mean, it's a defining thing about California is we love our amazing state and that's your beauty, the mountains, the beaches, that we all love that and I want to protect that. Um but here's the big part on this. The environment even green policies, that is not the same as climate and what what we now hear being described as the climate agenda and there's a lot more to environmental policy than carbon dioxide emissions and the climate. And so, when I think about what it means to be an environmentalist, it's protecting our beautiful open spaces. Now, let's talk about climate policy because when you the reason that we have the highest gas prices in the country, higher than Hawaii, in the middle of the Pacific Ocean, which is insane when you think about the fact that we have plentiful oil and gas reserves in California. We're paying higher gas prices than Hawaii. It is the direct result of what the Democrats call their climate agenda. So, let's break it down. Number one, it's the gas tax. People focus on the gas tax. Yes, it's true that it's the highest in the country. It's about 65 cents of every um gallon, but actually bigger component of the reason we have higher gas prices here than anywhere else is not the gas tax. It's these climate regulations, the low carbon fuel standard, which forces California providers to import ethanol from Iowa to mix with our own gas. It's insane. The cap and trade system, which is actually a tax, a hidden tax again on anyone who produces or uses fossil fuels. That massively increases the price, but that tax, where's that money going? High-speed rail, which which is obviously a complete disaster, not going anywhere. Then you look at the refinery regulations. It costs more to refine oil and gas here in California cuz you have all these different you have a winter blend and summer was complicated regulations. So, refineries are closing down. And then the final component is the attack on our own oil and gas industry in California. So, not that long ago, we used to produce most of the oil and gas that we use in California here in California, mainly in Kern County where most of our oil reserves are. Now, most of it is imported. We only produce about 20%. We are importing oil from halfway across the world on giant supertankers spewing out carbon emissions. Guess where our number one provider of oil is today. Used to be California the number one provider. Now, Iraq. How does that make any sense? Their environmental standards are much lower than ours. So, all of these things that are done in the name of climate change are not even delivering those objectives cuz we're actually increasing carbon emissions cuz we're importing all this oil when we could be using it. Instead of shipping it on these giant supertankers, we could be putting it in a nice clean pipeline Kern County to the refineries on the coast. It's insane. It doesn't make any sense. It's not even meeting their own objectives. So, I would get rid of all of that and we can do that through changes to the regulatory environment You do it through CARB, the California Air Resources Board. You replace the people there and you give them the clear mandate to deliver lower gas prices and [7:15] >> Yes, through CARB and my plan is to repeal the low carbon fuel standard, to change the way cap and trade tax is levied, to change the refinery regulations, to open up oil and gas production in California. All of that together, instead of where we've got now which is $5 gas heading to $6 or even higher, my plan is for $3 gas in California. And I can do that through changes to the regulatory environment without legislation. [7:45] >> As much as possible. I mean I I support that industry wholeheartedly. I want you know, we're going to need a lot of money to beat the

---
snapshot_id: 56da8d67-ffdf-5566-a52b-2e5b2ffac603
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:14] >> Are we ready to save our beautiful state of [0:37] >> Democracy is under threat. >> Everyone agrees we need change. That's what I'm fighting for. [1:17] >> We can turn things around. You just have [7:39] >> So Caitlyn and Alex, it's interesting. We've already seen a couple of things that we'll probably see a lot of in this debate, which is the Democrats who are here who've been responsible for 16 years of one party rule for everything that we see in California won't take responsibility and all they can talk about is Trump. Look, I was asked how I'm preparing for this debate the other day. And my answer was the meetings, the thousands of people that have come to our events the last year in California. I've traveled to every part of the state. I've seen the struggle and the stories and that is my struggle and my stories. My parents were immigrants. The California dream is my dream and I want that for every single one of you watching out there. We can get it [8:39] >> So, they should vote for the candidate who's got a concrete plan to make our state calffordable. $3 gas, cut your electric bills in half, your first hundred grand taxfree, a home you can afford to buy. It's common sense, practical things. Most of my career has been in business. I know how to get things done. And we need to change. We need some fresh thinking. after 16 years of one party rule from these Democrats that have given us the highest poverty rate as you mentioned the highest unemployment rate and the highest cost of living in the country. [10:06] ahead. >> It's not Donald Trump who's given us gas prices $2 higher than the rest of the country. It's Democrat policies, which Antonia and all the Democrats here support. It's not Donald Trump that's given us the highest housing costs in the country. It's Democrat policies that all these Democrats support. Donald Trump is the president in all the other states of America where the cost of living is way lower than in California. Obviously, it is way past time for change in California and endlessly going on about Donald Trump doesn't serve the needs of the struggling families and small businesses. >> Can you say whether or not he won the election? [14:23] Hilton. >> So, so Matt says that it's obviously impossible to get to $3 gas. Um, as I have laid out in my plan, before the Iran war, there were 40 states in America with $3 gas or lower, most of the which don't have the abundant oil reserves that we have in California. But because of the policy supported by Matt and all these Democrats, we are now shipping oil halfway around the world, 7,500 miles from places like Iraq instead of opening up California oil and gas production so we can reduce costs and get $3 gas in California, which is my plan. [15:00] >> Secretary Bera. [24:05] >> It is. There's there's a very simple truth uh which everyone in California knows which is that taxes are too high and we need taxes to be lower and they're especially too high for working people in California. You got people on 70 80 90 grand in California which doesn't get you very far who are paying 9.3% state income tax. That is higher than the top rate in most other states. That's why my plan eliminates state income tax under 100 grand. And by the way, if you think that it can't get worse in California, I've got two words for you. Tom Styer. Under Tommy Styer, the taxes will be higher. Gas prices will be higher. Everything will be higher with Styer. [26:43] >> Thank you, [29:29] >> So I'm I'm the only immigrant on stage. I'm a legal immigrant and Americans support immigration when it is properly controlled. And what we saw under the Biden administration, open borders undermined everybody's support for immigration. And as governor, I've made it very clear although it is the federal government's responsibility to to um determine and implement immigration policy, I think it's important that all the laws are peacefully enforced. And as governor, I would make sure that we work with the federal government to enforce our laws. Expect [30:11] workers? >> The the policy on deportation is the exact same policy that we saw with President Obama. In fact, the numbers of deportations right now in our country and in California are slightly just to clarify your point. Can you answer the question? I answered the question which is I will work. >> Will you deport him? >> That was the question. >> Well, would you Antonia? Because the governor of California, as you know, doesn't make that decision. It is the president of the United States elected by the country. [34:43] >> I I don't want to respond to to silly name calling, but I'd like to actually respond to something Katie said, and I think it's probably a sincere policy um difference between us. She said something very revealing which is the only way really that California's economy has been growing in the last few years is through illegal immigration. And I just don't think that's the right way for us to be growing. I think we need to help small businesses create jobs and opportunity and for Californians to be able to earn more and live the California dream and for entrepreneurs to want to start businesses in California. That's how we should be growing our economy, not by [35:23] consequences of that decision, >> Katie, it's I there's a difference I think you'll accept between legal and illegal immigration. [43:18] Hilton, >> um Antonio mentioned uh me earlier and said I just recently arrived. It's true. I arrived here in 2012 with my wife and my two sons. But what's interesting is that um I don't think there's an appreciation of the difference between legal and illegal immigration. I've spent many many times right here in East LA where we are with legal immigrants with families of legal immigrants who really resent the unfairness that we're seeing in California where you have illegal immigrants who are getting free benefits, housing, welfare, and they say to me, "Look, we did it the right way. We worked hard. the right way. Candidates, don't worry. >> We are not getting fairness and we need to restore fairness in our [45:34] >> I think the next governor of California will have to work with the administration and with the president that the American people elected to get good results for Californians. And by the way, my attitude will be to work with the president regardless of party to get good results for Californians. Now, it so happens that we have a president who has endorsed me for governor, and we've discussed how I can work with his team to lower gas prices in California by opening up energy production, to reduce wildfire risk, by proper forest management, to get the fraud and the waste out of our state budget so we can cut taxes. These are all practical ways we can work together to help everyone. >> Thank you, Mr. California. [55:54] singlepayer healthcare. >> Just listen to these Democrats arguing about whether to go left or even further left when that's the direction that's got us into this mess, the highest cost, the highest taxes in the country. I'm the only person here with actual experience of singlepayer healthcare. Both as a patient and as a policy maker. As a patient, it nearly killed me. That's another story we don't have time for. As a policy maker, you end up with the worst patient satisfaction, cost that you can't afford, taxes skyhigh to pay for it. It is a total disaster. And the actual way we deal with health care in this state is to at least stop spending $20 billion a year on free health care for illegal immigrants who [64:17] Court has stopped you from being able to [64:21] that's a lie. My my view is that it's a bit rich for Javier to talk about following the law when he is mired personally in a corruption scandal where his former chief of staff Shan McCcluskey when Javier was appointed by Joe Biden to be health secretary he wanted his chief of staff to go with him. The salary wasn't enough. So what did they do? They took money from Javier's campaign account to top up his salary by funneling it to Dana Williamson, Gavin Newsome's former chief of staff, so that it was paid to this guy's wife. All of that is illegal. It is against state law. It's against federal law. My running mate for attorney general, Michael Gates, has this evening written to Javier Bera to make it clear that when he is attorney general, Javier will be investigated and if necessary, prosecuted for these crimes. [65:21] >> I'm not going to weigh in on something that I don't have the knowledge of the facts on. I trust that Chad is interested in what we should all be interested in, which is ensuring the integrity of our elections and restoring faith in our elections in California. That's why I support voter ID in California. Let's see what these Democrats think of voter ID. [66:24] chief And it was your decision. [66:29] Washington as health secretary and you wanted him by your side. And the reason that the money was transferred is because the salary wasn't high enough. That's why you engaged in this scheme which is [67:47] >> And just today, I launched a new plan for starter homes in California. One of the most heartbreaking things I see is young people, they come to our events and I asked them, "Do you ever see yourself owning a home in California, starting a family here?" And they say, "No, and we're going to have to leave." And that's why we've got to enact a very straightforward plan. Number one, we have to get rid of the regulations that make it two or three times as expensive to build the exact same home in California as in neighboring states. We have to stop the lawsuits filed by the unions who support these Democrats that get in the way of building housing. And to your point, we have to stop trying to force housing into suburban neighborhoods where people don't want it. Instead, we have to build single family homes in the places in our state that do want to expand. That's the plan to make sure that we can restore that California dream of home ownership. It is the heart of opportunity for our young people and it's being taken away by these Democrats and their policies. >> Mayor Mayanm, your response. [81:02] >> Mr. [81:04] Hilton, >> look, this is a very serious moment for California. The ballots are out. They're in your hands. And we have a really big choice to make, which is do we go for another four years of one party rule that's given us the highest taxes for the worst results, the highest poverty rate, highest unemployment rate, highest cost of living, serious policy questions, homelessness. We need to stop homelessness and end it. We need to stop funding fiascos like highspeed rail. We need to lift burdens on our business. That's what this debate needs to be about. And the only way to get the change we need is to [86:13] >> It's classic Democrats, isn't it? What you're hearing. Um, if it moves, tax it. If it still moves, regulate it. And if it stops, move it. I guess they want to subsidize it. Look, the truth is on this we have to have a bit of humility. This is a very fastmoving technology and actually even the people involved in it disagree about its exact consequences. Here are two things that we two practical things we could and should be doing better today. First of all, the real bluecollar jobs that are coming from the AI revolution, they're not happening in California. They're going to Texas and Arizona semiconductor manufacturing. We could get that back by removing regulations. And secondly, our school system is not educating our kids to be able to thrive in the world of AI. We need to [89:30] >> I think that was my word. Would you like [89:32] that charge? >> Again, I don't want to respond to silly insults, but I'll take the substantive point, which is first of all, when Tom talks about um uh tripling subsidies for electric vehicles, let's be clear what that is. That is higher taxes on hardworking Californians driving their gas, cars, and trucks every day so that Tom's rich friends can feel virtuous about saving the climate. The truth is, we need common sense on climate change. It doesn't make sense to import oil from halfway around the world, increasing carbon emissions in the name of climate. It doesn't make sense to allow mega wildfires in our forests that actually release more carbon dioxide than what is saved by all these climate policy. [96:06] Hilton. >> Um, so highspeed rail is an example of the fraud. Um, they've spent billions of dollars. I don't know where the money's gone. It certainly hasn't gone into building anything that actually works. And I just want to make one broader point about fraud. I'm actually running this race in a different way than we've seen before. I've put together a team to run with me. There are other statewide offices. And along with my running mate for state controller, Herb Morgan, and Michael Gates for attorney general, and Gloria Romero for Lieutenant Governor, we've actually been investigating the fraud. Our survey so far suggest that there in the last five years in California, we've had $425 billion dollars of fraud. That's around 80 billion a year, around 20% of the budget. And our team is going to stop it and prosecute it and give money. [96:54] >> real quickly, mayor. [99:59] I guess that would be a good one. [100:00] Clint Eastwood. >> Okay. Mr. Hilton. >> I think there's only one choice really. Jason [102:45] rest of the state? Well, um, if you ask my wife and my sons, often to their great embarrassment, it's that I absolutely hate bureaucracy and ridiculous, pointless rules and regulations that crush the life out of uh, people and businesses and daily experience that we have. And so, I just want to tell everyone, I'm going to be relentless, absolutely relentless in fighting the nonsense that makes life so difficult for each and every one of you. I will not rest until we restore sanity to our beautiful state of

---
snapshot_id: 1202d2b9-b18f-55e4-a049-8c0cf6e9d318
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: 6d7ef017-2fd3-510b-9017-3bfd3deca75a
source_kind: news (excerpt only)
url: https://calmatters.org/california-voter-guide-2026/governor

… Controller Treasurer Superintendent of Public Instruction Board of Equalization Insurance Commissioner Supreme Court U.S. House State Senate State Assembly Prop 1 Housing bond Prop 2 Rainy day fund Prop 3 High-income tax Prop 4 Public fundraising Prop 5 Recall reform Prop 37 Homebuyers loan Prop 38 Research bond Prop 39 Voter ID Prop 40 Billionaire tax Prop 41 Tax audits Prop 42 Property taxes Prop 43 Tax threshold Prop 44 Clinic funding Prop 45 Environmental review Quizzes es Leer en español Governor of California The California governor is the most powerful elected official in the nation’s most populous state, commanding a $300 billion budget. The governor shapes policy for 39 million residents, signs or vetoes legislation, appoints judges and members of regulatory agencies and leads crisis response from wildfires to pandemics. California’s governor wields outsized national influence, making the office a launching pad for presidential ambitions. Xavier Becerra D Steve Hilton R Candidates Xavier Becerra D Democratic Former U.S. Health secretary, former state attorney general Becerra represented Los Angeles in Congress for more than two decades before being appointed California’s attorney general in 2017. He led the state’s numerous lawsuits against the first Trump administration and Republican states. He was U.S. secretary of Health and Human Services under President Joe Biden, steering the administration through the COVID-19 vaccine rollout and receiving criticism for the agency’s lack of care of migrant children in its custody. Becerra says he’s open to revising California’s climate goals to keep fuel affordable and wants to declare a state of emergency to freeze utility and insurance rates. Steve Hilton R Republican Former adviser to UK prime minister, former Fox News host Hilton, who is British American, was senior adviser for former conservative U.K. Prime Minister David Cameron from 2010 to 2012 before moving to California, where he …