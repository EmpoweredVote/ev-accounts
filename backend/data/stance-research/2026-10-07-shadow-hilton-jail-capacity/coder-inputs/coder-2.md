You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-jail-capacity/labels/coder-2.json. Write JSON only, matching
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

### topic_key: jail-capacity
topic_id: c267e137-0ff9-4e7d-9d13-e3cea1756cd0  served_revision_id: 7992fadf-a24c-4f73-bd34-76b5bca4764b
Question: How should government respond to jail overcrowding and criminal justice demand?
  1. Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system
  2. Reducing the incarcerated population through alternatives to incarceration rather than building new capacity
  3. Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity
  4. Building additional jail capacity to address overcrowding and facility deficiencies
  5. Expanding jail capacity as the primary response to crime, prioritizing detention over alternatives

#### Annex

# jail-capacity — served revision 7992fadf-a24c-4f73-bd34-76b5bca4764b (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`f63a4e70-…`); coders code the served text below.

**Question:** "How should government respond to jail overcrowding and criminal justice demand?"

**Orientation:** standard. Rung 1 moves money out of incarceration to shrink the jail system, rung 5
expands jails as the main response to crime. The rungs order **the size of the jail system**: shrink
it, reduce its population, hold capacity, add capacity, make detention the primary tool.

**Levels with a lever:** local, state. Counties fund, build and run jails
(boards of supervisors or commissioners, sheriffs); states fund jail construction, set bail and
sentencing law, and run prisons. No federal officeholder holds a lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "jail", "detention center", "correctional facility", "beds" / "rated capacity",
"overcrowding", "consent decree", "conditions of confinement", "jail bond", "certificates of
participation", "pretrial services", "diversion", "bail reform", "electronic monitoring",
"mental-health court", "drug court", "restorative justice", "justice reinvestment", "care first".

1. **"Redirecting incarceration funding into community-based mental health, addiction, housing, and
   restorative justice programs to shrink the jail system"**
   - Means: take money away from jails and spend it on community programmes, so the jail system gets
     smaller.
   - Operative clauses: [a] redirect incarceration funding (money leaves jails or prisons);
     [b] into community-based programmes (mental health, addiction, housing, restorative justice);
     [c] to shrink the jail system.
   - Establishing evidence looks like: a budget amendment or motion that cuts jail or sheriff
     detention funding and moves it to such programmes; a jail closure plan that reinvests the money.
     New programme money with no cut to incarceration has no [a] → rung 2 territory _(proposed)_.
   - Levels that hold a lever: local (county budgets); state (prison and jail funding).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both reduce the jail population. Rung 1 needs money moved
     **out of** incarceration.
   - The four programme types name forms of [b]; one form is enough _(proposed)_.

2. **"Reducing the incarcerated population through alternatives to incarceration rather than building
   new capacity"**
   - Means: lower the number of people held by using alternatives, instead of building more space.
   - Operative clauses: [a] reduce the incarcerated population through alternatives; [b] rather than
     building new capacity.
   - Establishing evidence looks like: a diversion, pretrial-release, treatment-court or bail-reform
     measure **plus** evidence against new capacity (a No on a jail expansion, or own words). An
     alternatives programme alone does not exclude rungs 3 and 4 → `compound-partial` _(proposed)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Bail reform, pretrial diversion and treatment alternatives are now all inside "alternatives to
     incarceration"; any one of them meets [a].

3. **"Upgrading jail facilities only as needed to meet constitutional standards, without expanding
   overall capacity"**
   - Means: fix jails so they meet constitutional standards, but do not add beds.
   - Operative clauses: [a] upgrade facilities only as needed for constitutional standards;
     [b] without expanding overall capacity.
   - Establishing evidence looks like: a renovation or replacement project tied to conditions
     (a consent decree, a court order, an inspection finding) whose bed count does not grow. Read
     the capacity numbers; [b] must be stated, not assumed (V4.2 "Silence is not a clause").
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a "replacement jail" can be larger than the old one. If
     the rated capacity grows → rung 4.

4. **"Building additional jail capacity to address overcrowding and facility deficiencies"**
   - Means: build more jail space to deal with overcrowding and poor facilities.
   - Operative clauses: [a] build additional capacity; [b] to address overcrowding and facility
     deficiencies.
   - Establishing evidence looks like: a vote for a jail expansion or a new, larger facility, justified
     by crowding or conditions. A capacity vote alone does not exclude rung 5 → `direction-only`,
     unless the same record or the person's words keep alternatives in place _(proposed)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.
   - Commonly confused with rung 5 because both add beds. Rung 5 adds the claim that detention is the
     **primary** response to crime and comes **before** alternatives.

5. **"Expanding jail capacity as the primary response to crime, prioritizing detention over
   alternatives"**
   - Means: add jail space as the main answer to crime, and prefer detention to alternatives.
   - Operative clauses: [a] expand capacity; [b] as the primary response to crime; [c] detention
     over alternatives.
   - Establishing evidence looks like: a capacity expansion **plus** own words or records that rank
     detention ahead of alternatives (for example opposing diversion or pretrial release while
     funding beds).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Enforcement is no longer part of this rung. More police or tougher sentences with no capacity
     clause do not reach rung 5 → `adjacent` _(proposed)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Prisons.** State prison capacity is on-question: the question names "criminal justice demand",
  rung 1 names incarceration funding, and prisons are the state's lever _(ruled 2026-10-01)_.
- **Bail and sentencing law** with no capacity or population clause → `adjacent`; the judicial
  topics order those rules _(proposed)_.
- **Jail health care, staffing and wages** improve operations without changing capacity → `adjacent`
  _(proposed)_.
- **Bonds and capital plans** are a record when the person votes on the specific project; a county
  budget that funds the whole sheriff's office → V4 `multi-subject`.
- **Feasibility studies and needs assessments** → V4 `study-directive`.


## Sources

---
snapshot_id: 3de031fe-9646-57a4-8bcb-bc04e7a5de7e
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000

Saved from https://stevehiltonforgovernor.com/policies/no-state-income-tax-on-your-first-150000 (rendered page text, built-in browser, 2026-10-07) POLICY NO STATE INCOME TAX ON YOUR FIRST $150,000 ← POLICY ARCHIVE NO STATE INCOME TAX ON YOUR FIRST $150,000 THE PROBLEM California families are getting squeezed from every direction. Housing costs are out of control. Utility bills keep rising. Groceries cost more. Insurance costs more. Child care, gas, and health insurance continue to get more expensive. For too many Californians, it feels harder every year to get ahead. At the same time, the political establishment keeps asking Californians to pay more while delivering less. The quickest, simplest, and most direct way to put more money in people’s pockets is for the government to take less out. Yet today, California’s government is gouging working families and small businesses with some of the highest taxes in America. California has the highest income tax rate in the nation. The highest statewide sales tax rate. The highest gas tax. Over the last decade, state spending has roughly doubled. Yet the results have gotten worse. California now ranks 50th out of 50 states for opportunity in U.S. News & World Report’s Best States rankings. California has the highest poverty rate in America when cost of living is taken into account. California has one of the highest unemployment rates in the nation. California’s highway system ranks 49th out of 50 states overall, and 50th out of 50 for urban arterial pavement condition. Californians are paying more than ever, yet getting less in return. California’s 9.3% income tax bracket begins at roughly $72,000 of taxable income for married couples. That rate is higher than the top income tax rate in most states. THE HILTON PLAN Under Steve Hilton’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. Millions of Californians would see an immediate tax cut and keep more of their own money for housing, childcare, groceries, retirement savings, or whatever matters most to their families. The result is a tax system that is lower, simpler, and fairer for California families. WHAT IT MEANS FOR YOU For a married couple filing jointly using the standard deduction and assuming an 8% tax rate on income above $150,000: A family earning $150,000 would pay no California state income tax. A family earning $200,000 would save more than $7,000 every year. CAN CALIFORNIA AFFORD IT? Whenever Californians ask for tax relief, the political establishment says there’s no money. Yet California is projected to collect more than $226 billion in General Fund revenue this year. Independent estimates suggest eliminating state income tax on the first $150,000 of income and applying an 8% rate above that threshold would reduce revenues by approximately $40 billion annually. That represents roughly a 17.6% reduction in projected General Fund revenues. The elimination of state income tax on the first $150,000 of income accounts for approximately $20.9 billion of that total, or about 9.2% of projected General Fund revenues. Even after this tax cut, California would still collect roughly $187 billion in General Fund revenue every year. That is about the same amount the state collected in 2020-21. At the start of that period, California had roughly 200,000 more residents than it does today. If California could serve a larger population with roughly the same revenue then, it can do so again today. Californians are not undertaxed. State spending roughly doubled. Housing costs soared. Utility bills rose. Insurance premiums climbed. California became less affordable. And when the political establishment claims there is no room for tax relief, Californians have every reason to be skeptical. During the pandemic, California’s Employment Development Department lost an estimated $50 billion to $55 billion in fraud and improper payments. The State Auditor found that EDD did not take substantive action to strengthen fraud detection until months into the pandemic, paid billions in claims it could not verify, and even paid an estimated $810 million in fraudulent claims filed under the names of incarcerated individuals. California spent nearly $24 billion on homelessness programs over five years. The State Auditor found that state officials could not consistently measure whether the spending actually reduced homelessness. Before asking Californians to pay more, government should prove it can responsibly manage the money it already receives. Californians deserve tax relief. State government should learn to live within a budget that was sufficient just a few years ago. THE BOTTOM LINE Under Steve’s plan, Californians will pay no state income tax on their first $150,000 of income. Income above $150,000 would be taxed at a simple 8% rate. For millions of families, that means thousands of dollars every year staying in their household budget instead of going to the government. California’s affordability crisis won’t be solved by asking families to pay more. It will be solved by letting them keep more of what they earn. ← Back to all policies

---
snapshot_id: 1feca005-6746-52f0-abb2-4b478a0e3e30
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business

Saved from https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business (rendered page text, built-in browser, 2026-10-07) POLICY ENDING THE WAR ON SMALL BUSINESS ← POLICY ARCHIVE ENDING THE WAR ON SMALL BUSINESS Small businesses create jobs, keep communities alive and give people the chance to build something of their own. They are an essential part of social mobility and the opportunity to build generational wealth. But the Democrats running California have spent years treating small businesses like a cash machine…or a problem to be managed - rather than a beautiful, vital part of our economic life and social fabric. Owners can owe the state $800 before earning a dollar. They spend hours dealing with rules nobody can understand and money defending extortionate shakedown lawsuits over footling technical discrepancies. Rents, energy and insurance bills keep rising, hiring gets more expensive and projects wait years for approval. It all adds up. Enough is enough. Steve Hilton is the candidate of small business, for small business. ‘Small business owner’ is his actual designation on the ballot. Steve has started and run a range of small businesses, including restaurants. He knows exactly what it’s like to try and stay afloat in the face of tiny margins, tough economic conditions and endless harassment and nonsense from government and bureaucratic agencies. Steve will end the Democrat war on small business, and give this essential part of our economy the freedom and support it needs. California’s small business owners have never had as passionate and committed a champion as Steve Hilton will be as governor. 1. CUT CALIFORNIA’S REGULATIONS BY MORE THAN HALF California has more than 420,000 regulatory requirements and prohibitions. By the end of his first term, Steve will bring that number below 200,000. Each state agency will have a public reduction target and will have to show its progress. A regulation should stay on the books only if it protects against a real harm and its benefit justifies its cost. Any major regulation expected to cost Californians $50 million or more will require an independent cost analysis and a public vote by the Legislature. Elected lawmakers should have to specifically justify regulations that impose undue costs on the public, with the default assumption that they are not justified. Starting a business will no longer mean chasing different agencies for registrations, licenses and permits. California will create one place to complete the state process, recognize comparable occupational licenses from other states and eliminate licenses that no longer serve a public-safety purpose. 2. END SHAKEDOWN LAWSUITS Trial lawyers and unions have turned California law into an extortionate shakedown racket. Small businesses are threatened with ruinous litigation over footling technical discrepancies, obviously manufactured complaints, and failure to comply with insane, pointless, bureaucratic processes created solely to generate more work for the trial lawyers who bribe the politicians that write these ridiculous laws. The legal process is engineered in a way that forces businesses to settle even when nobody has suffered real harm. It’s disgusting. Steve will enact real tort reform. PAGA will be ended by actually following the law as written, with the Labor Commissioner taking the first step in labor law enforcement, as laid out in Steve’s End PAGA plan, published last year. Employers who cheat their workers will still be punished. Private trial lawyers will no longer bring cases in the name of the state and collect enormous fees. A small business that makes an honest first-time mistake will receive clear notice and a reasonable opportunity to correct it before fines or lawsuits begin, provided the violation was not deliberate and caused no serious harm. The same protection will apply to construction-related accessibility claims. Businesses will still have to make their properties accessible, but an owner who promptly fixes a violation will not be forced to pay state statutory damages and attorneys’ fees. Fraud, repeated violations and conduct that puts people in danger will not qualify. 3. CUT THE COST OF EMPLOYING PEOPLE California forces private employers to navigate a separate workplace safety bureaucracy even though a national OSHA standard already exists. Steve’s Safe and Califordable Workplaces plan will move private employers to the federal OSHA baseline. California will keep a state plan for state and local government workers. This will reduce the cost of employing people, especially for small and fast-growing businesses. For a first-time, non-willful violation by a small business, the first response will be help rather than a fine. The business will receive plain-English guidance and 30 days to correct the problem. Written compliance questions will be answered within five business days. Employers who knowingly put workers in danger, retaliate against workers or repeatedly ignore violations will face tough enforcement. California-only rules that do not make workers safer or merely duplicate federal requirements will be repealed or rewritten. Workers’ compensation is supposed to help people injured on the job. Too much of the money is swallowed by lawyers, delays and fraud. Steve will set a first-term goal of cutting California’s workers’ compensation premium burden by at least 25 percent. Legitimate claims will move faster, the legal and administrative costs that drive up premiums will be cut, and fraud will be prosecuted. State Fund will also be reviewed and reformed if it is not lowering costs and helping injured workers. 4. ABOLISH THE $800 SMALL BUSINESS TAX California charges LLCs and many corporations at least $800 every year, even if the business loses money or never opens its doors. Steve will abolish this tax and veto any new state tax or fee that raises the cost of starting or running a small business. A business that earns no profit should not owe the state $800 simply for existing. 5. PAY OFF CALIFORNIA’S UNEMPLOYMENT DEBT California’s federal unemployment debt is driving up payroll taxes for employers every year through FUTA taxes (Federal Unemployment Tax Act). The most recent level is a 2.1% surcharge for every employee. This is an absolutely massive scandal, on so many levels. First, the tens of billions of dollars paid out by the Employment Development Department (EDD) should never have been needed in the first place: it was all a consequence of the cruel and counter-productive covid lockdowns, totally unjustified on any public health grounds, that viciously targeted small businesses while leaving many large businesses able to stay open. Secondly, the utter, disgraceful incompetence of the EDD led to over $30 billion being stolen in fraud, error and identity theft, including checks sent to prisoners on death row and United States Senators. It was an unforgivable dereliction of duty by Xavier Becerra’s Sacramento machine, and still no-one has been held accountable. Third, the gross negligence and incompetence of the Sacramento machine meant that California was the only state to not pay back its federal loan. And now every small business in our state is paying the price for the uselessness of our politicians and their appointed bureaucrats. Steve will pay off the debt by the end of his first term using savings from elsewhere in state government. Small businesses who were first penalized by the covid lockdowns should not be penalized again with a tax increase. Employers who did not create the debt will not be handed another state tax increase to cover it. Steve will also pursue legal remedies against Julie Su, now Deputy Mayor for Economic Justice under Mayor Mamdani in New York, and reduce the pay of all senior EDD officials who were working in the Department during this scandal. 6. PROTECT MAIN STREET FROM THEFT Retail theft is not victimless. Small-business owners pay through lost inventory, higher insurance premiums and added security costs. Proposition 36 will be fully funded and implemented, including the enforcement and treatment voters approved. Business owners should not have to accept theft as another cost of operating in California. Beyond these specific measures to help small business, Steve will cut the taxes, rules, lawsuits and other costs that make it so hard to run a small business in California. In particular, Steve’s other plans to cut energy costs will make a huge difference to every small business in California. Small businesses pay California’s high energy costs through their own gasoline and electricity bills and through the price of everything delivered to them. Steve’s Califordable energy plan will increase production in California and reverse rules that drive investment out of the state. The cost of every proposed energy regulation will have to be disclosed before it is adopted. California will not impose a vehicle mileage tax. The goal is $3.00 gas and cutting electric bills in half. ← Back to all policies

---
snapshot_id: 1854011f-bebd-5088-a4ed-55eab58f2bd1
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals

Saved from https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals (rendered page text, built-in browser, 2026-10-07) POLICY CRACK DOWN ON MASKED CRIMINALS ← POLICY ARCHIVE CRACK DOWN ON MASKED CRIMINALS Tougher Penalties for Criminals Who Deliberately Hide Their Identity THE PROBLEM Criminals who wear masks or disguises while committing robberies, burglaries and other serious crimes are not doing it by accident. They are trying to conceal their identity, avoid being recognized and make it harder for police to catch them. California law recognizes that this is wrong, but the penalty is hopelessly outdated. Penal Code Section 185 makes it a misdemeanor to wear a mask or disguise for the purpose of evading identification while committing a crime. The law dates back to the 19th century and still refers to disguises including “false whiskers.” That may have made sense when the law was written. It is not an adequate response to someone who deliberately masks up to commit a serious felony today. California should treat the deliberate concealment of a criminal’s identity for what it is: an aggravating factor that makes the crime more serious and makes it harder to solve. STEVE’S PLAN Steve will work to create new sentencing enhancements for criminals who deliberately conceal their identity while committing a felony. If prosecutors prove that someone committed or attempted to commit a felony while intentionally using a mask, hood, disguise or other facial covering to avoid identification, apprehension or prosecution, the criminal would face an additional one, two or three years in prison. For violent and serious felonies, the additional penalty would increase to two, three or five years. This would not restrict lawful mask wearing. It would apply only when prosecutors prove that the defendant was committing a felony and deliberately concealed their identity in order to help commit the crime or escape responsibility for it. Other states have already adopted similar laws. North Carolina, for example, increased penalties in 2024 for crimes committed while wearing a mask or disguise to conceal the offender’s identity. California should do the same. Someone who deliberately hides their identity while committing a serious crime has made an additional choice to evade law enforcement and avoid accountability. Our criminal law should recognize that choice and punish it accordingly. THE BOTTOM LINE California already has a law against concealing your identity while committing a crime. The problem is that the law is antiquated and the punishment is too weak. Steve will update it to make sure California once again backs law enforcement and comes down hard on criminals who deliberately try to hide who they are. If you deliberately mask up to commit a felony, you should face additional prison time. If you do it while committing a violent or serious felony, the penalty should be even tougher. ← Back to all policies

---
snapshot_id: 4df63756-d7dc-5448-b545-2314f281084e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/fd5e0064-917c-4522-9ed4-e3fa71f289c1

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Candidates on Homelessness (CBS News) - OTR page: https://ontherecord.empowered.vote/meetings/fd5e0064-917c-4522-9ed4-e3fa71f289c1 - Video: https://www.youtube.com/watch?v=EHkU_NAZJZ4 - Date on On the Record: 2026-04-12 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [0:15] homeless population? Enforce the law, get people into treatment, and increase mental health capacity by getting a waiver from the Medicaid IMD rule that stops any um institution with more than 16 beds getting Medicaid funding. Enforce the law, get people off the streets into treatment, whether that's drug treatment, um mental health treatment, job training. We got to get we Look, here's a simple way of putting it. We wouldn't accept someone we loved living in those conditions on the street. [0:45] >> You require the treatment. And and that's why [0:48] >> it's it's it's actually illegal under California law because in 2016, a bill was passed which has become known as Housing First. That's the name of the policy. It was actually originated in the Obama administration as federal policy implemented through HUD, Housing and Urban Development. California was the only state to actually turn that into state law, which makes it illegal for any organization receiving state money for homelessness to require any kind of response from the from the client, whether that's treatment or or anything. So, what you have is this crazy situation. I've been there. So, [1:28] >> What do you [1:31] Well, again, my first step, invite the legislature to overturn this law. Um if they won't do it, then we have to step in at the state level through executive action to to Just as Gavin Newsom is doing right now. I mean, he's he's sent just just on the day that we're um recording this conversation, he made an announcement that he's What's he going to do? He's going to have crime suppression teams sending in uh from with state resources, state law enforcement going in um to cities and he's going to clean homeless homeless The the latest promise is clearing homeless encampments in 30 days. And so, he's using the power of the state to forcibly act where cities and counties haven't done their job. And if he can do it, then so can I. And I will. And let's hope, by the way, that he has dealt with the problem. I hope he does work. I hope it does work this time and isn't just the latest example of of words from Gavin Newsom that aren't matched by

---
snapshot_id: e2285f4c-5768-5c05-b790-d373a9ffcc91
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: c39168e9-1d40-5b8d-95da-63d6c5d28ce3
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee

Saved from https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee (rendered page text, built-in browser, 2026-10-07) POLICY THE WORKING CLASS HEALTHCARE GUARANTEE ← POLICY ARCHIVE THE WORKING CLASS HEALTHCARE GUARANTEE Reducing Costs to Make Healthcare Available and Affordable for Working Families in California California politicians boast about how many people have an insurance card. That misses the point. The real test is whether people can see a doctor and afford the bill. Most Californians under 65 get insurance in one of three ways. More than half get it through an employer. More than one-third of Californians rely on Medi-Cal. A much smaller number buy coverage through Covered California or directly from an insurer. Each part of the system works differently, but all three are dragged down by the same problem: California has never seriously confronted the underlying cost of healthcare. Workers pay through payroll deductions, deductibles and lower wages. Medi-Cal patients may pay little or nothing in premiums but struggle to find a doctor. People buying insurance themselves face California's high healthcare costs directly. Steve Hilton will take on the cost of healthcare itself. That means exposing prices, bringing in more providers, cutting out middlemen, stopping fraud and giving patients control over the money spent in their name. That way Steve can deliver the most important missing piece of the healthcare system in California today: a Working Class Healthcare Guarantee - healthcare that is available to working families in California for an affordable premium and with a low deductible that doesn't make a mockery of the whole idea of health insurance. THE PROBLEM Healthcare in California is too expensive and too hard to get. Patients rarely know what a service will cost before receiving it. State rules limit who can provide care and make it harder to open clinics or expand hospitals. Pharmacy benefit managers and other middlemen make money from deals patients never see. The result is predictable. Prices rise. Insurance premiums rise with them. Patients pay more while doctors and independent providers spend more time fighting through bureaucracy. California politicians respond by spending more government money and enrolling more people in government programs. Then they declare success. But more spending is not success if families still cannot afford care, and an insurance card is not much use if nobody will take it. HOW CALIFORNIA GOT HERE Insurance was supposed to protect people from large and unexpected medical bills. It has become a complicated payment system for almost every medical service. Patients do not see the real price, and providers have little reason to compete directly for their business. California made matters worse by piling on mandates, licensing restrictions and approval processes. The biggest institutions learned how to work the system. Smaller providers and patients were left to pay for it. Steve's plan starts from a simple principle: the system should work for the patient, not the people who control the paperwork. THE PLAN 1. CUT THE COST OF EMPLOYER HEALTHCARE Employer coverage is not free. In 2025, the average California employer plan cost more than $10,000 for one person and more than $28,000 for a family. Workers may not see the whole bill, but they pay it through contributions, deductibles and wages swallowed up by rising healthcare costs. Bringing those costs down starts with prices. Hospitals, physician offices, outpatient centers and pharmacies will have to show patients real dollar prices before nonemergency care. California already collects huge amounts of payment data, but much of it is buried in files almost nobody can use. A price hidden in a computer file is not transparency. Steve will put the information on one website where patients and employers can make real comparisons. Prescription drugs are another obvious place to act. California has recently passed restrictions on pharmacy benefit managers, including a ban on spread pricing in new and renewed contracts. Those rules will be enforced and the remaining loopholes closed. The state will publish cash and Health Savings Account prices for the 100 most commonly used generic medicines. Patients will be allowed to pay the lower cash price when it beats the insured price, and unnecessary barriers to lawful mail-order and out-of-state pharmacy competition will go. California also needs more people providing care. Some qualified nurse practitioners can now work independently, but the remaining restrictions are excessive. Steve will finish that reform, give qualified physician assistants greater authority and bring California into the Interstate Medical Licensure Compact so experienced doctors can start practicing here without an unnecessarily slow licensing process. The same approach applies to clinics and hospitals. California already has a 30-day approval process for a narrow group of clinics affiliated with experienced nonprofit operators. Steve will make rapid approval available to any qualified neighborhood clinic that meets clear health and safety requirements. Hospital projects will face firm review deadlines. Limited extensions to California's 2030 seismic deadline already exist, but too many hospitals remain at risk of closing because they cannot meet an arbitrary timetable. Steve will expand the extension process and allow practical plans that protect earthquake safety without taking hospital beds out of a community. California should produce more of its own medicine too. Pharmaceutical enterprise zones in the Central Valley and Inland Empire will offer tax and regulatory relief to companies that actually manufacture essential and generic medicines here. No production and no California jobs means no incentive. These changes attack the costs that drive up employer premiums in the first place. That is how workers keep more of what they earn. 2. REPLACE BUREAUCRATIC MEDI-CAL WITH PATIENT CONTROL Medi-Cal functions as a separate, second-class system: fewer than half of doctors who have signed Medi-Cal contracts accept Medi-Cal patients, reimbursement runs at barely half of Medicare rates, and peer-reviewed outcomes data show Medicaid patients faring worse than comparably situated privately insured patients. California already spends more per Medi-Cal enrollee than the average cost of private insurance per enrollee, yet delivers worse access and outcomes. The problem is the structure of the benefit, not the level of spending. Medi-Cal spends thousands of dollars in a patient's name, but the patient controls almost none of it. Government agencies and managed-care organizations decide where the money goes. The patient gets a card and may still be unable to find a doctor. Fraud drains even more money away from legitimate care. California already has anti-fraud operations inside the Department of Health Care Services and the Attorney General's office, but responsibility is divided. Steve will put them into one California Health Program Integrity command working directly with federal investigators. Modern claims analysis can catch impermissible billing, duplicate identities and excluded providers before payment. Honest mistakes can be corrected. Deliberate theft will mean removal from the program, prosecution and repayment. The larger reform is to give patients control. For working-age adults who are not seniors or disabled, California will seek federal approval for personal healthcare accounts containing approximately $8,000 to $10,000 a year. Preventive care and protection against catastrophic medical costs will remain covered. Patients will use their accounts for qualified healthcare expenses and choose their own providers. Money left over will remain available for future care instead of disappearing at the end of the year. Doctors and clinics will have to compete for the patient rather than the patient begging a bureaucracy for permission. California will pursue a federal Section 1115 demonstration and begin in a region willing to participate. If it works, it can expand. Federal law already requires work or community engagement from many able-bodied Medicaid adults beginning in 2027. California should implement that requirement. Medi-Cal must protect children, seniors, people with disabilities and families going through hard times. It should not become a permanent destination for adults who are able to work. 3. GIVE PEOPLE BUYING THEIR OWN INSURANCE A REAL ALTERNATIVE The individual market covers a much smaller share of Californians, but the people in it feel every increase directly. They include self-employed workers, independent contractors, small-business owners and people who retire before becoming eligible for Medicare. They need a lower-cost alternative focused on what insurance is supposed to do: protect against major medical expenses without making ordinary care unaffordable. Steve's Working Class Healthcare Guarantee will give them access to coverage with an affordable premium and a low deductible. Californians who prefer high-deductible coverage paired with a larger and more flexible Health Savings Account will still have that option. To bring down premiums, Steve will apply for a Section 1332 State Innovation Waiver under the Affordable Care Act. Section 1332 allows a state to redesign its individual insurance market if the new system provides coverage that is at least as comprehensive and affordable, covers a comparable number of people and does not increase the federal deficit. California will use the waiver to establish a reinsurance program. Reinsurance pays part of the small number of exceptionally high medical claims so those costs do not drive up premiums for everybody else. When premiums fall, the federal government spends less on premium tax credits. Section 1332 allows those federal savings to return to California as pass-through funding to help pay for the program. Alaska used this approach through the Alaska Reinsurance Program, which covers claims tied to 34 high-cost medical conditions. Federal officials estimate that premiums are 38.5 percent lower than they would have been without the waiver. Reinsurance directly lowers the premium. California will combine it with existing state assistance and savings from the cost reforms throughout this plan to bring down the deductible too. Covered California's Bronze plans now work with HSAs, but California still refuses to recognize the full federal tax benefits of the accounts. Steve will end that state tax penalty. Qualifying plans will also be able to provide a $500 annual wellness contribution when participants complete eligible preventive care or healthy-lifestyle activities. The same Section 1332 waiver will seek approval for simpler coverage options that protect against major medical expenses without forcing Californians to pay for a long list of mandates they do not want. Californians buying their own coverage should have real choices, including a plan that delivers the affordable premium and low deductible promised by the Working Class Healthcare Guarantee. A BETTER WAY FORWARD California does not lack healthcare spending. It lacks a system that treats the patient as the customer. The current system answers to government agencies, insurers, hospital bureaucracies and middlemen. Steve will make it answer to the patient, and focus on delivering a new Working Class Healthcare Guarantee, with affordable premiums and low deductibles for working families. ← Back to all policies

---
snapshot_id: d78b057a-29cb-554c-9c2a-34b37eeaf068
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor's Debate (Nexstar) - OTR page: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e - Video: https://www.youtube.com/watch?v=qRNZ0kuA49k - Date on On the Record: 2026-04-23 - Kind: debate · Governor's Debate (Nexstar) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:15] Everyone can see things have gone off track. Life is impossible. [8:50] We have to make these changes because Californians are being crushed by the gas prices, by the gas tax. We have the highest gas tax in the country for the worst roads in the country. And across the board, we have the highest taxes for the worst results. And you know who's really suffering? It's working Californians. It's small businesses. Most of my career has been in business. I know what it's like to try and run a business. The costs that are being imposed on our businesses and our workers in California is just too much. And one way or another, all the Democrats here are part of this system that obviously isn't working. We need common sense solutions. We need practical solutions. Why are we importing oil from 7 ,500 miles away in Iraq rather than using the oil we have here in California? That's the kind of common sense change that as governor, I will be there to persuade the legislature to do. Because they, in the end, want to help Californians too. [10:05] The first point is that to open up California oil production doesn't need the legislature because it's through executive action. The way that they've been closing it down is through an agency of the executive branch called CalGEM, the California Department of Geologic and Energy Management. I would replace the people in there and give them a clear instruction to issue permits to our oil industry to produce oil here in California so we can cut gas prices for California families and businesses. [14:14] No, we cannot keep going in this direction with Democrats constantly going for their insatiable appetite for more and more taxes for their bottomless money pit, and now the mileage tax, they want to track you everywhere you drive. No, I would veto that. We need to cut spending and cut taxes so that we can give relief to families and businesses. My plan is for $3 gas and your first 100 grand tax free. That's what we need to do to make our state Cal affordable. [22:01] Well, by the way, I'd love to be in your class, Katie. If you get a B for what Gavin Newsom's done on homelessness, my goodness, of course it's an F. It shames our state, the situation with homelessness. We have about 10 % of the US population, around 50 % of the country's homeless population. And as for Javier praising Gavin Newsom for the photo op where he tried to pretend he was cleaning up a homeless encampment, literally, Gavin Newsom did that three times in a row. Nothing changed, and nothing will change if you have one of these Democrats in power. It will be more of the same. My plan is a common sense three -point plan. Number one, it is illegal to live and camp on the streets. We need to enforce the law. Number two, we need to get people into the drug treatment that they need, and it cannot be a choice. Number three, we need to get people the mental health care that they need instead of the barbaric situation we have right now in California as a result of these Democrat policies where the main place where we're treating people with mental health problems is jail. That has to change. [23:14] everything has taken us in the wrong direction. That's why we spend, what is it? The state auditor found $24 billion of our money spent on homelessness. They have no idea where it went because it's going into these nonprofits and crony developers that are, instead of solving the problem, they are profiting of these Democrat policies. Okay, Mr. Hilton, thank you. Your time is up, [33:17] One of the proudest days of my life was the day I became an American citizen. It happened in a ceremony right here in San Francisco. So it is a deep honor for me to be endorsed by the President of the United States and here's the thing that's gonna help every Californian when I'm governor is that we will have a constructive relationship and partnership with the federal government which would be the case, I would hope, for any party in that situation so that we can make things better in California, work with the president and his administration to manage our forests better, to harvest the timber so we can build the single -family homes we need for young families, to work to increase California energy production as he wants to do so we can lower gas prices, to fight the fraud in our government so we can cut spending and cut taxes, to work to enforce our immigration laws in all these areas and more. It will benefit every Californian to have a governor who is a partner on these issues with the president and his team. [36:17] that again, Tom. Wait, no, no. Mr. Hilton. [36:24] putting more money into the system. [42:39] So I've discussed this with someone called Marcus Coleman from Bakersfield. His beautiful daughter, Delilah, was put into a coma by someone driving a truck, an illegal immigrant, didn't speak English, and his daughter now disabled for life. That's what we're dealing with here. It is completely ridiculous that we have people driving on our roads who can't understand road signs and can't speak English. So yes, of course, and I've discussed this with my friend, Sean Duffy, the transportation secretary. We will not be issuing commercial driver licenses when I'm governor to people who are illegally here and who don't speak English. That is obvious common sense. [50:46] I will because we've had 16 years of one party rule by these Democrats. It's given us the highest poverty rate, the highest unemployment rate, the highest cost of living in America. It is obviously desperately time for change in California. It's time for some balance in our system. We have to elect a Republican as governor this year. [54:31] We obviously need change in California. The system is not working. I'm the only one here who has never run for office before. I'm not part of this system. These Democrats can't get it done. Matt Mahan talks about his record in San Jose. Actually, homelessness and crime are going up. Javier Becerra talks about his time in government. He thought it was a good idea to put masks on two -year -olds. We need real change in California. We need to think different. We need to vote different. My plan to make our state Cal -affordable is real and serious, and we can get it done if we just vote differently this year. [59:33] Well, if San Jose is the template for housing affordability in California, God help us, it was just rated the least affordable city for housing in the world. That is completely the wrong answer. The right answer is my plan, which was the first plan that I put forward in this campaign. Number one, we have to end this outrageous hidden tax on housing. They call it impact fees. It can add up to 20 % to the cost of a home. Secondly, we have to reduce the extreme environmental regulations that make it three or four times as expensive to build the exact same home in California as in neighboring states. Number three, we have to end the exploitative union lawsuits that are filed to block housing that extract project labor agreements that make the cost so much higher. And number four, we have to end the war on single -family homes so that we can build the housing we need for young families. We need more starter homes in California. [65:54] It's an absolute scandal that we have just under half of our students can read at grade level for math. It's 35%. Here's the plan. We're gonna learn from what works in other states and around the world. The best way to teach kids to read, phonics. We're gonna have that in every school. The most important thing is that you learn to read by the end of third grade. Just as Mississippi has done, we're gonna make sure, we're gonna give you help over the summer if you can't but if you don't meet the test, you repeat the grade and then you can move forward and we're gonna hold teachers and schools accountable for their performance. [70:09] We have to be clear about why they left. They left because of Democrat policies and wrong -headed regulation. Now, some of those mistakes have been corrected. The ability for insurance companies to price in future risk, the ability of insurance companies to account for reinsurance costs, but we still have wrong regulation and this is the three -point plan that I've announced to fix this absolutely massive problem that is crushing so many families across California. Number one, we've got to get people off the fair plan. It was designed for about 100 ,000 people. Now you've got over 600 ,000. We've got to work proactively to get those people onto commercial insurance. Number two, we have to stick to the regulatory framework that was in the original proposition that set up the insurance department. 60 days to make to approve rate changes. Sometimes now it's over a year. And number three, we have to stop these nuisance lawsuits often filed by private equity from out of state that are increasing the cost of insurance. All right, [75:53] So as the father of two teenage children, I know this issue very well. But actually it's an issue that I've been thinking about and advocating on for many, many years. 11 years ago, in my book, More Human, 2015, that was published, I made the argument that it's not just the apps, it's not just the platforms, it's the screens themselves and that we should set a social norm that children under 16 should not have a smartphone. That is my position now. I think that every parent in their heart knows that it's wrong. Kids do not need smartphones and we shouldn't allow it. [76:38] I think it misses the point, honestly. I think that we've got to get to the heart of the problem and that's the devices and the screens. [82:14] In the middle of it right now is Reacher. One of my sons really enjoys that. Probably more than the rest of us in the family but it's been good fun to watch together.

---
snapshot_id: 7d2db2df-0fca-51b9-9a61-f3e1464b68a7
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/hilton-and-yolo-county-da-jeff-reisig-unveil-crime-fighting-plan/

Hilton and Yolo County DA Jeff Reisig Unveil Crime-Fighting Plan - Steve Hilton for Governor Skip to content ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate Hilton and Yolo County DA Jeff Reisig Unveil Crime-Fighting Plan Share This June 18, 2025 12:09 pm Hilton and Prop. 36 Architect and Yolo County DA Jeff Reisig Unveil Crime-Fighting Plan at Site of Closed State Prison SACRAMENTO, CA — California gubernatorial candidate Steve Hilton, along with Prop. 36 architect and Yolo County District Attorney Jeff Reisig, held a press conference on Tuesday, June 17, 2025, at the closed Deuel Vocational Institution to expose the dangerous consequences of Gavin Newsom’s prison closure agenda and present a bold, commonsense plan to hold criminals accountable so that crime is properly punished and prevented. Located in Tracy, Deuel Vocational Institution was one of four state prisons shut down under Newsom’s soft-on-crime policies, which have fueled early releases, overcrowded jails, and rising crime across California. The shuttered facility served as a powerful symbol of failed leadership and the need for urgent change. “Newsom’s decision to close prisons while crime surges is the definition of backward,” said Hilton. “The number of criminals should determine prison capacity; prison capacity should not determine the number of criminals, which appears to be the current state policy. This is what happens when ideology replaces common sense. Gavin Newsom closed prisons, overcrowded local jails, and landed us with a broken system that neither holds criminals accountable nor deters crime. My plan will reverse the damage by expanding prison space so we can ensure real accountability and the opportunity for effective, smart rehabilitation.” Hilton and Reisig laid out key components of Hilton’s Crime-Fighting and Prison Reform Plan , including: Reopening shuttered state prisons to relieve overcrowded county jails and ensure there is enough space to incarcerate violent and repeat offenders. Ending early release programs that reward “good conduct” while ignoring serious disciplinary records or the severity of crimes committed. Tying early release credits to rehabilitation milestones , such as earning a GED, completing vocational training, or finishing addiction or mental health treatment programs. Replacing ineffective government rehabilitation programs with performance-based contracts for private providers, ensuring inmates leave prison equipped to reenter society and contribute positively. Overhauling the state’s failed realignment policy , which dumped state-level inmates onto county systems not designed to handle the volume or complexity of their needs. Restoring accountability and deterrence by ensuring California’s criminal justice system prioritizes safety over political ideology. “California has empty prisons, overcrowded jails, and a justice system that fails to hold criminals accountable or give them a real shot at turning their lives around,” Hilton said. “This plan restores order, expands opportunity, and makes safety a priority again.” See the video here: https://x.com/SteveHiltonx/status/1935368333924171851 ### For more information about Steve Hilton’s campaign and vision for California, visit www.stevehiltonforgovernor.com . Share This Steve Hilton For Governor X-twitter Instagram Facebook Youtube Paid for by Steve Hilton for Governor 2026 By entering your phone number and selecting to opt in, you consent to receive SMS/MMS marketing and polling text messages, donation requests, updates, and other important information to that number from Steve Hilton for Governor. Msg&data rates may apply. Msg frequency varies. Reply HELP for help or STOP to opt-out at any time. SMS information is not rented, sold, or shared. View Privacy Policy and Terms & Conditions. To make a donation by check, please send your contribution to: P.O. Box 730 Hilmar, CA 95324 Press Inquiries ONLY: [email protected] Copyright &copy; 2026. Steve Hilton for Governor. All Rights Reserved Campaign News Contact Privacy Policy

---
snapshot_id: c8c66f46-0ed1-5fe0-aaff-2d44ce8918b9
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/crime

Steve Hilton for Governor of California