You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-nosource/labels/coder-3.json. Write JSON only, matching
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

### topic_key: same-sex-marriage
topic_id: c5ab4eab-702f-49b8-9277-8ea53f3835c6  served_revision_id: 8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f
Question: What legal recognition should same-sex marriages receive?
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


### topic_key: ukraine-support
topic_id: 24e9212c-b011-422a-865c-093e35050901  served_revision_id: 9ee7ecb7-fd99-429a-a37d-eff58a381983
Question: What level of military and financial support should be provided to Ukraine?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: education-gender-identity
topic_id: d96f987e-3404-4667-909d-5889116ba6e5  served_revision_id: 89f9d4a5-362e-4470-9529-46d4826fdeb9
Question: What should schools do when a student uses a different name or gender identity at school than at home?
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


## Sources

---
snapshot_id: 502ab94e-918a-530f-a4fd-49797324c6c7
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/1dc4a5f7-2f0b-48a6-919e-67def1629e4f

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Candidates on Congressional Redistricting (CBS News) - OTR page: https://ontherecord.empowered.vote/meetings/1dc4a5f7-2f0b-48a6-919e-67def1629e4f - Video: https://www.youtube.com/watch?v=DR4SRUWANjI - Date on On the Record: 2025-10-06 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [4:42] redistricting plan? Well, it's totally corrupt and it's unconstitutional and it's illegal. Beyond even the the constitutional changes that he's trying to make through the ballot initiative that he's trying to get on the ballot. In fact, I'll be filing a lawsuit challenging its constitutionality in federal court, which hasn't been done yet by the the various opponents of this. But let's just take a step back, which is we all agree, I think, that politicians shouldn't draw their own maps. I mean, that's obviously wrong and corrupt. Common sense tells you that. [5:12] doing? So Texas is following its constitution, however. So Texas didn't change its constitution to take the power to draw the maps out of the hands of the politicians, put it in the hands of the people, which we did here. We No one wanted this. There's no one in California saying to the politicians, "Please, give us new maps." Well, there [5:33] >> I know, but lower gas prices, give us lower housing costs, give us more jobs. That's what people want. So I would much rather this whole thing wasn't happening. And the cost of it, 250 million dollars taxpayer money for something that nobody really wants apart [22:06] Republicans. Today's maps, never mind what Gavin Newsom wants to do. Today we have a massively distorted uh political map in California. We have very stable Republican vote in statewide elections over the last 20 years from around 40% of the vote. Across the state. Um that's really steady. Republicans don't have 40% of their representation in Congress anything like. It's actually less than half that. It's 17% and with this new plan that they've got it will be down to 6%. Now I understand that the districts aren't supposed to be a perfect match in terms of uh proportional representation, but it's not supposed to be wildly out of step with that. Right now if you look at the actual just the total number of votes cast it basically takes around 600,000 or so votes to elect a Republican to Congress. It it takes around 200,000 votes to elect a Democrat to Congress. A Democrat vote in California today is worth three times what a Republican vote is. With these new maps it's going to be even it's going to be eight times. Eight times. So we are completely violating the principle of equal protection. [27:02] >> Texas didn't change its constitution to take the power to draw the maps out of the hands of the politicians, put it in the hands of the people, which we did here. The rules are that you draw the maps straight after the federal census every 10 years. By drawing these maps in the middle they don't know who lives where. Millions of people have left California. In in Los Angeles whole communities have burnt down. Who knows