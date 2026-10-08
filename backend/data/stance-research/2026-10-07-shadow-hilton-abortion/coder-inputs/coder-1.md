You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-abortion/labels/coder-1.json. Write JSON only, matching
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

### topic_key: abortion
topic_id: af2fdfd6-02c4-49df-b09c-cf8536f4773f  served_revision_id: 085feb9c-f157-4dae-bfd0-7b2736c5d87c
Question: How should the law handle abortion?
  1. keep abortion legal at every stage of pregnancy, with no time limit.
  2. keep abortion legal through the second trimester, and after that only to protect the mother's health.
  3. allow abortion during the first trimester, and after that only to protect the mother's health.
  4. ban abortion except in cases of rape, incest, or a serious risk to the mother's life.
  5. ban abortion in all cases, with no exceptions.

#### Annex

# abortion — served revision 085feb9c-f157-4dae-bfd0-7b2736c5d87c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris
Andrews). Lines marked _(proposed)_ are a drafter's reading, not yet ruled. The season pin is an
older revision (`dab46e5c-…`); coders code the served text below.

**Question:** "How should the law handle abortion?"

**Orientation:** standard. Rung 1 has no legal limit, rung 5 is a ban with no exceptions. The rungs
order **when** abortion is legal and **which exceptions** apply after that point.

**Levels with a lever:** federal, state. The lever is state law;
federal action is national limits or protections; local governments rarely hold one, so a local
officeholder is coded on own words.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "gestational limit", "weeks of gestation", "post-fertilization age", "LMP" (last
menstrual period), "viability", "heartbeat" (an early limit, about 6 weeks), "medical emergency",
"life of the mother", "reproductive freedom", "fundamental right", "fetal personhood".

**Weeks and trimesters.** The rungs state limits in trimesters; laws state them in weeks. The first
trimester ends at about 13 weeks, the second at about 27. **Read the weeks as the law states them**
(LMP or post-fertilization); do not convert _(ruled 2026-10-01)_.

1. **"keep abortion legal at every stage of pregnancy, with no time limit."**
   - Means: no point in pregnancy after which the law forbids abortion.
   - Operative clauses: [a] legal at every stage; [b] no time limit.
   - Establishing evidence looks like: own words that reject every gestational limit; an instrument
     that removes the jurisdiction's limits and says no limit remains _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **declared right** reads like "no limit". A text that
     declares a right to abortion and names no limit has said nothing about limits; other law may
     still set them → `direction-only` (V4.2 "Silence is not a clause").
   - Public funding is no longer part of this rung. A funding bill does not move a person along these
     rungs → `adjacent` _(proposed)_.

2. **"keep abortion legal through the second trimester, and after that only to protect the mother's
   health."**
   - Means: abortion is legal until about 27 weeks; after that, only for the mother's health.
   - Operative clauses: [a] legal through the second trimester; [b] after that, a health exception
     only.
   - Establishing evidence looks like: a limit at about 22 weeks or later — up to about 27 weeks, or
     at viability — with a health exception after it.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the limit falls between the two thresholds. A limit at
     **16–21 weeks** establishes neither rung → BLANK `direction-only` _(ruled 2026-10-01)_.
   - A limit with **no** stated exception after it does not reach rung 2 on its own (V4.2 "Silence is
     not a clause"). A limit with a **life-only** exception after it → `compound-partial`, the same
     as rung 3 _(proposed, by analogy with the rung-3 ruling)_.

3. **"allow abortion during the first trimester, and after that only to protect the mother's
   health."**
   - Means: abortion is legal early in pregnancy; after that, only for the mother's health.
   - Operative clauses: [a] legal during the first trimester; [b] after that, a health exception
     only.
   - Establishing evidence looks like: a limit at about **12–15 weeks** with a health exception after
     it (a medical emergency that covers serious lasting harm to the mother, not only death) — **but
     only when the law actually permits abortion up to the limit**, either affirmatively or by
     repealing a broader ban. Then it excludes rung 2 (it bans most of the second trimester) and rung
     4 (it allows abortion for any reason before the limit). A 15-week limit is within the ladder's
     precision for "first trimester" _(ruled 2026-10-01, revised the same day)_.
   - **Read the act's construction or savings clause.** A limit that says it does not create or
     recognize a right to abortion, does not make lawful any abortion that is now unlawful, or leaves
     a broader ban in force, evidences **no permitted stage**. A vote for it shows only the
     restrictive side → BLANK `direction-only` _(ruled 2026-10-01)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_. A gestational-limit bill is chair-shaped only
     when it permits abortion before the limit (see the construction clause above).
   - Commonly confused with rung 2: see rung 2.
   - A **life-only** exception after the early limit is narrower than "to protect the mother's health"
     → BLANK `compound-partial` _(ruled 2026-10-01)_.
   - A limit with **no** stated exception after it does not reach rung 3 on its own (V4.2).

4. **"ban abortion except in cases of rape, incest, or a serious risk to the mother's life."**
   - Means: abortion is banned, with three exceptions.
   - Operative clauses: [a] a ban; [b] exceptions for rape **and** incest **and** a serious risk to
     the mother's life.
   - Establishing evidence looks like: a ban with all three exceptions. An **early ban** (for example
     at about 6 weeks) with all three exceptions is in practice a ban with those exceptions → rung 4
     _(ruled 2026-10-01)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 when the ban has a **life-only** exception. It has an exception, so
     it is not rung 5; it lacks rape and incest, so it is not rung 4 → BLANK `direction-only` _(ruled
     2026-10-01)_. A ban with life and health exceptions but no rape or incest exception → the same
     _(proposed)_.

5. **"ban abortion in all cases, with no exceptions."**
   - Means: abortion is banned at every stage, with no exception at all, including for the mother's
     life.
   - Operative clauses: [a] a ban; [b] no exceptions.
   - Establishing evidence looks like: own words that reject every exception, including the mother's
     life. [b] is an absence clause: a ban that lists no exception does not show that none applies,
     because other law may supply one (V4.2) _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Criminal penalties for patients and providers are no longer part of this rung → not evidence for
     or against it _(proposed)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Narrow restrictions** that set no gestational limit and no exception rule (parental
  notification, waiting periods, clinic rules, reporting) → `adjacent`; BLANK `no-evidence` when
  nothing else survives.
- **Medication-abortion rules** (who may prescribe, by mail or in person) → `adjacent` _(proposed)_.
- **Fetal-personhood measures** that define life from conception but state no ban or exception rule
  → `direction-only` _(proposed)_.
- **Preemption (codebook V2, H12)** → `adjacent`.
- **Budget and omnibus votes** with an abortion item → V4 `multi-subject`.


## Sources

---
snapshot_id: 668d7e45-0808-54d6-bd03-592826e97ea3
source_kind: news (excerpt only)
url: https://calmatters.org/california-voter-guide-2026/governor

… Controller Treasurer Superintendent of Public Instruction Board of Equalization Insurance Commissioner Supreme Court U.S. House State Senate State Assembly Prop 1 Housing bond Prop 2 Rainy day fund Prop 3 High-income tax Prop 4 Public fundraising Prop 5 Recall reform Prop 37 Homebuyers loan Prop 38 Research bond Prop 39 Voter ID Prop 40 Billionaire tax Prop 41 Tax audits Prop 42 Property taxes Prop 43 Tax threshold Prop 44 Clinic funding Prop 45 Environmental review Quizzes es Leer en español Governor of California The California governor is the most powerful elected official in the nation’s most populous state, commanding a $300 billion budget. The governor shapes policy for 39 million residents, signs or vetoes legislation, appoints judges and members of regulatory agencies and leads crisis response from wildfires to pandemics. California’s governor wields outsized national influence, making the office a launching pad for presidential ambitions. Xavier Becerra D Steve Hilton R Candidates Xavier Becerra D Democratic Former U.S. Health secretary, former state attorney general Becerra represented Los Angeles in Congress for more than two decades before being appointed California’s attorney general in 2017. He led the state’s numerous lawsuits against the first Trump administration and Republican states. He was U.S. secretary of Health and Human Services under President Joe Biden, steering the administration through the COVID-19 vaccine rollout and receiving criticism for the agency’s lack of care of migrant children in its custody. Becerra says he’s open to revising California’s climate goals to keep fuel affordable and wants to declare a state of emergency to freeze utility and insurance rates. Steve Hilton R Republican Former adviser to UK prime minister, former Fox News host Hilton, who is British American, was senior adviser for former conservative U.K. Prime Minister David Cameron from 2010 to 2012 before moving to California, where he …

---
snapshot_id: 29a40e2f-40c3-5813-b4b8-db21c2979b50
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## news_clip — CA CA-Courier-SteveHiltonInterview - OTR page: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7 - Video: https://www.youtube.com/watch?v=VIZ1h4OaImU - Date on On the Record: 2026-04-01 - Kind: news_clip · CA-Courier-SteveHiltonInterview · CA - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:04] to be with you. [0:33] Well, the first thing we've got to say is why we need to cut taxes in California because we have an insane level of taxation. We have the highest taxes in the country for the worst results and one of the consequences of that is that we have on all these measures the worst performance of any state. It's really shocking. Right now we have the highest poverty rate in the country tied with Louisiana. We have the highest unemployment rate of all 50 states. We have the highest cost of living. We have the worst business climate according to Chief Executive Magazine for the last 10 years. So businesses are leaving, investment is going, jobs aren't being created. That's why we have high unemployment and high poverty. So a huge part of that is the tax burden and we've got to reduce it and that means you have to reduce spending. So that's the starting point. When you look at who's really suffering as a result of all these things, not just the taxes but the high cost of gas and housing, groceries, all of these the most expensive in the country. Electric bills, the second highest after Hawaii, insurance, all these unbelievable burdens. Working class Californians are hurting the most. Regular working people who work incredibly hard and everything's so expensive and then they're taxed for it. And so the first, I mean in many counties, the official poverty level [1:52] is now $100 ,000. So in many other states, you look at $100 ,000 and think that's a decent income. In California, it doesn't get you very far. So the last thing we should be doing is taxing those people. That's why I wanted to start with that. $100 ,000 to raise the threshold for paying state income tax. That would help millions of Californians, thousands of dollars extra in their budgets every year. That one, I think that we can, I think there's a very real prospect of getting out through the legislature because one thing I've noticed is that my tax plan, that part of it has actually been copied. By some of the other Democrat candidates, including Katie Porter. So I think that actually we can get support for that part of it. That's the pro -worker part. The second part, which is a flat tax above $100 ,000, 7 .5%. Now that is going to be much harder to implement. Partly because a lot of these taxes are not just too high, they're too complicated. We've got endless different tax bans that make it really fiddly and annoying and bureaucratic to do your taxes. And it's a real disincentive to start businesses here. I'm a business owner. Most of my career has been in business. And it's just a nightmare. And the taxes are a big part of it. Now, some of those tax rates that we have have been established by ballot initiative over the years. That's one of the reasons we have this complicated system. So it won't be easy to undo that. But I think we've just got to make the argument. And so my attitude to all of this is your starting point is see what you can get done through the legislature. Then see what you can get done through executive action, through the administrative agencies. And then if none of that works, then for these really major reforms, we probably will have to go to a ballot initiative at some point in the future, after I'm elected and take office in January. [3:53] to. I mean, that's how it works. That's how our system works. So I've got a very strong focus. You know, when I'm the general election candidate, I'm very clear that my responsibility as the top of the ticket in California is to help elect Republicans everywhere. It's not just about my race. It's about the other statewide races. I'm the first candidate ever from either party that's put together a team to run for the other statewide offices. We can get to that a little bit later. But in terms of the legislature, it's going to be a huge priority for me to try and help elect more Republicans this cycle in the assembly and the Senate because then we do have a chance to break the supermajority this year. It's not going to be easy, but it's not impossible. So even if we get rid of the supermajority in one of the two chambers, that's already really helpful because then they won't be able to just block everything. And so you start to create some opportunity there. I think also the truth is that [4:51] when I'm elected this year, nobody expects a Republican to win in terms of the Democrat. They're so arrogant. It's 16 years of one party rule. They think it's going to go on forever. But actually, I think we've got a very good shot this year. When I'm elected, that's going to be a political revolution in California. And I think when I take office in Sacramento in January, it really will change the dynamic. I really believe that. It's hard to imagine it right now, but it's going to be a shock to these Democrats that they've got a Republican governor. And I think we will be able to do that, to work with them. And there's a couple of things I'd add. Number one, I've got experience of doing that. So most of my career, as I said, I've been in business, working around the world, but also starting my own companies, including restaurants, a whole range of different businesses. But I have had a few years working in government at a very high level. I was senior advisor to the prime minister in the UK. I worked in 10 Downing Street. I had a little office there next to the cabinet room and worked to try and make things happen. In a coalition government. So my boss was David Cameron, the conservative prime minister, but it was a coalition with another party, the Liberal Democrat Party. And I shared an office with my opposite number in the other party, Polly McKenzie. We used to argue a lot, but we also worked together to find the areas where we could make change happen. So I've got experience of doing that. It's not easy. And of course, you're not going to get everything done that way, but it's not true to say nothing can happen. And I think that it really will [6:17] change things to have a Republican governor. I think the whole mood in Sacramento will change. A lot of things that are seen as impossible will suddenly start to become more realistic. The other thing I'd point to now talking about the team I've put together to run with me for the other statewide offices, including for lieutenant governor. [6:34] And that's the concept of a ticket has never been done before in California, statewide races. But I think we've got to try new things and do things differently. Gloria Romero, who's running with me for lieutenant governor, she was previously the Democrat leader in the state Senate. So that was many years ago. And she left the party. She used to work across the aisle, but then the party went very left -wing. I met her when she was working with Rick Grinnell on a ballot initiative for school choice. It was Rick who introduced me to Gloria. And she's now a Republican, fully signed up. She's endorsed President Trump, spoke at the Coachella rally. But she still has relationships there. As the lieutenant governor, you're the president of the Senate. And so you have a big role to play. She understands how that system and the process work in the legislature. And so I'm running, I'm obviously an outsider. I've never run for office before. And I'm going there as an outsider to take on all the nonsense in Sacramento. But I think it's gonna be helpful to have by my side someone who has been there and knows how it works and has relationships in the Democrats. I mean, I went there with Gloria. We were launching some policy thing and went into the state Capitol. And it's a long time since she's been there and she's a Republican now. But they invited her onto the Senate floor as a mark of respect. She was previously the leader. I watched it from the gallery. They all stood and cheered. [8:01] Democrats, because there's relationships there. And so I think that it seems very out of reach, the idea that we could actually have something positive happen. But I don't know, I've got a very strong feeling that in these various ways, we really can get some things done. [8:49] Well, the first business I started was 1997, a company called Good Business. And we were a consulting firm. We worked with some of the biggest companies in the world. Then about two years later, we launched, with my business partner, we launched a couple of restaurants in the UK called The Good Cook, which is kind of an offshoot of our consulting business, but it was two real restaurants in London. And they were, that's a really tough business, to be honest. You learn a lot from it, but in some ways we did well, in other ways it was tough. It's very difficult to make money in that business. Then I went back into politics and government, worked in 10 Downing Street for a while. We moved here in 2012 with my wife and my two sons. And for the first couple of years I was here, I talked at Stanford, but then I launched another business here, a tech company, a tech platform called CrowdPak. And that was a crowdfunding platform for politics and candidates and political causes. And so that's an equivalent, you could think of it as a GoFundMe for political candidates and so on. And so that was a business that started, I think, well, I got going 2013, probably launched 2014. Ran that for a few years before being invited to host a show on [10:07] Fox News. And then after that, the final business that I started was a media company, really to produce podcasts and so on. That was CR Productions. So there's been the four in total. So that's that. I don't know what he's talking about with this fast track thing. It's completely ridiculous. We, you know, it wasn't that fast. We moved here in 2012 [10:32] on a visa that [10:34] then got applied for a green card and got that and got my citizenship in 2021, nine years. So I actually genuinely don't understand what that's about. Do you have any more specifics on what the allegation is? [10:52] years? Yes. Is that fast? [11:01] I literally think that is a completely made up, ridiculous smear, which I don't even understand. I don't understand why someone would question the process there when it's just an independent, bureaucratic process. They're saying that everyone has to go through. [11:18] It's really ridiculous. [11:23] So what specifically, that I don't understand. Again, what was the specific thing there? [11:36] Well, partly we've just been discussing how important it's gonna be to be able to work with Democrats in order to make change happen. But actually, I think what's being referred to there is one of my businesses, CrowdPak, which is a crowdfunding platform [11:52] for politics and candidates and so on. And it was an open platform. So like GoFundMe, or like X. So I think what he's getting at there is that Democrats used my business to raise money, as did Republicans, as did anyone who wanted to. So it's a little bit like criticizing Elon Musk for things that Democrats say on X. It's an open platform. Yeah, people can use it. [12:38] Well, again, I think we have to be practical. I've always been really clear that I never wanna say something that can't be delivered just to make people feel good about whatever the issue may be. I always wanna be realistic about what you can do. And on this particular issue, which is so deeply felt and is so personal for so many people, I think there's just a couple of things I'd say. First of all, I do think that it's right that the issue was now, for so many years, it was in the hands of judges and the people felt they didn't have a say. And thanks to President Trump's Supreme Court appointments and where that led, it now has been put back in the hands of the people through their representatives, because states have been able to make their own determinations on that issue. And you've seen a wide range of policies implemented across America. And I totally support that approach, because the idea that you've got one size fits all on something that's so personal and people have such strong views about was always one of the real problems with this issue. People felt that their voices weren't heard. Now, in the end, you've gotta decide what level this is regulated. It has to be regulated at some level. Previously it was the national level, now it's at the state level. And so in different states, they voted for different things. Here in California, in 2022, it was on the ballot [13:57] to be enshrined in the state constitution, the right to abortion. And it was, and it was passed with a two -thirds majority. So that's how it works. That's how the system works. So my attitude to this is what can I get done as governor to move us in this sort of direction of life, towards life, in a way that I can actually deliver. So the first thing I'd say on that is that all the other things that I wanna get done for California to make it, to make our state, as I say, Cal affordable, to make this a place where young people wanna, can see a future where they can start a family here. One of the most heartbreaking things to me is when you talk to young people and they say, well, I can't imagine living in California. It's too expensive. I'll never be able to do it here. I have to move to another state. I want this to be a place where people see the opportunity to start and raise a family and have children and grow their families here in California, something I talked to Charlie Kirk about a lot. He was a good friend of mine and endorsed me on day one. And it was a big thing, big focus for him as well. That ability to, because you hear stories where people say, yeah, I'd love to have more children, but [15:07] it's too expensive or I can't afford, I can only afford a tiny apartment and so I can, et cetera. They've got to change all that. So that's actually part of the story of moving us towards life. More specifically on the issue itself, [15:19] you've got a couple of things. First of all, I think we have to just encourage a culture of responsibility on this. One of the things that I just think is really, I'm gonna use a pretty strong word, it's kind of disgusting actually, is the way that, it's just the way that this issue has evolved, particularly in places like California, is that it's almost as if abortion is now seen as a perfectly acceptable form of birth control, just like any, and I just think that's really, really dark and not where we want to be as a society. So you have to, [15:50] and the governor can, through working with the faith, I've had lots of conversations, for example, with Jack Hibbs, who's a big supporter of mine from Calvary Chapel, Chino Hills, and others in the faith community about how we can work together to encourage more responsibility, a culture of responsibility. So we minimize the number of unwanted pregnancies in the first place. So there's something you can do more actively on that as governor, and I will. Secondly, if you are in that situation, I think it's just outrageous that what you're seeing now from the government in California is actively [16:22] attacking pro -life centers and places that are, I just met someone who runs one of those this morning, encouraging adoption, for example, as an alternative and helping prospective mothers think through that process. That's being discouraged and actually aggressively targeted by the Newsome administration. So that we need to reverse and encourage adoption as an alternative. And then the final piece of it, I just think this whole spending taxpayer money promoting abortion, which is what's happening right now, our money is just not okay, including, [17:02] again, stuff that I just think is really wrong, like what some people have described as abortion tourism, [17:09] where our taxpayer money is being spent on ads in other states, [17:14] saying, come to California, all that's gonna stop. [17:32] Well, again, I don't really understand what he's talking about, because I think what he said something about, the way he framed it was as if what I was saying wasn't true. I've never said anything about him that's not true. Nothing. I mean, the things that I've been pointing out are things that are true about his record, unlike what's been said about me, as we've just discussed, not true at all. And people can watch for themselves. I think what he's getting at is the fact that when he was, as sheriff, during the Black Lives Matter riots in 2020, he took a knee for Black Lives Matter. And he argues that he was praying. I've never said one way or the other. I've just said, and it's clear that he took a knee. That's a physical action, taking a knee. And you can see that. It's documented, there's video, there's photographs. You can watch it, it's on a website, blmbianco .org. So people can see that for themselves. So it's obvious that he took a knee. He challenges the interpretation of that as being something that was done for BLM. And he says he was praying. That's what he says. He said it many times. I've heard him say it many times. Now, people just watch the video and see if that's true. I don't think I've ever said anything about that that's not true. And it's not backed up by documented evidence on the day. The second thing I've pointed out, and maybe he's getting at this, is again, just repeating what he said on an issue that is actually probably the biggest policy area where we really have a disagreement, which is on immigration, where he has said a number of things that I just strongly disagree with. He said that he won't, and his sheriffs in his department, won't work with the federal authorities to enforce immigration law. I disagree with that. The Sanctuary State Law in California allows for cooperation between state and federal law enforcement on immigration. So I don't know why he would not want to do that. But he said that. It's a video, you can watch it. The other part of this that I strongly disagree with is his contention that people who are here, who came across the border during the Biden years, are actually here legally. And his view that, which again, I'm quoting almost word for word now, that it doesn't matter how you came here, the 10 to 11 million people who came under Biden, the illegal immigrants here, we have to give them a pathway to citizenship. I just disagree with that. That's rewarding law breaking. We, as I often point out, we already have a pathway to citizenship. It's called legal immigration. I just took it. And so I just disagree. Now he may not [20:12] like the fact that when this issue comes up, I'm pointing out his past statements, but they're his words. I've never said anything that's not true. [20:26] to be with you. Thank you.

---
snapshot_id: d9ae1b0d-960c-5f1c-ae43-472e6e3b6627
source_kind: pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)
url: https://www.ontheissues.org/Steve_Hilton.htm

Steve Hilton on the Issues Follow @ontheissuesorg On the issues: Steve Hilton Hilton's Profile Governor Match | Other CA Candidates: Antonio Villaraigosa Eleni Kounalakis Eric Swalwell Gavin Newsom Katie Porter Tom Steyer Xavier Becerra Zoltan Istvan CA Governor (Republican challenger) Steve Hilton On the issues>> Wikipedia Ballotpedia Contact Steve Hilton Take the Quiz! VoteMatch CA politicians Governors (2026 election unless otherwise noted; AK : Mike Dunleavy (R,term-limited) vs. Click Bishop (R) vs. Nancy Dahlstrom (R) vs. Tom Begich (D) vs. Jonathan Kreiss-Tomkins (D) vs. Bernadette Wilson (R) vs. Bill Walker (I) AL : Kay Ivey (R,term-limited) vs. Doug Jones (D) vs. Tommy Tuberville (R) vs. Will Boyd (D) vs. Yolanda Flowers (D) AR : Sarah Huckabee Sanders (R,for re-election) vs. Fredrick Love (D) AZ : Katie Hobbs (D,for re-election) vs. Andy Biggs (R) vs. David Schweikert (R) vs. Karrin Taylor Robson (R,withdrew) CA : Gavin Newsom (D,term-limited) vs. Xavier Becerra (D) vs. …

---
snapshot_id: e8043ba5-4302-56f7-bfdd-f2acb5dfb264
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [7:19] the change we need is away from the policies that have brought us to the situation that all the people on this stage described there's a difference though only two of us here actually represent real change away from that like millions of people before me I came to this state in search of a dream like my parents who left communist Hungary to England in search of freedom I was brought up in a working -class immigrant family I made it to Oxford University started a business worked in 10 Downing Street came here in 2012 my wife and my two sons taught at Stanford started a business and now leading the race for governor I want every single one of you to know that I see you I believe in you I won't accept that the California dream is something we talk about in the past tense wherever you want to go I want to clear the barriers away more money in your pocket your first hundred grand tax -free enough with the bureaucracy and the nonsense we will restore the California dream [15:51] I love the way Matt talks about how he's gonna lower costs when his city was recently rated the most expensive the least affordable for housing in the world [16:06] he's not fixing it because he's not fixing it because we're building housing are as high this year as they ever were all the plans he talks about have not actually reduced the cost of housing because fundamentally he supports the policies that have made housing and gas the most expensive in the country we need a change from those policies not more of the same I [22:13] well I don't think it's fair that California taxpayers who can barely afford their own health coverage should be paying for the health care of citizens of other countries and if you look at the record of Javier it's exactly what was just saying that you cannot believe that any change will come from these people he as health secretary dismantled the unit and HHS that was supposed to crack down on fraud billions of dollars of fraud as a result of his rule as HHS secretary and there's another point I think we have to acknowledge we learned today that Javier implicated in this corruption scandal today we learned that he knew about illegal and improper payments from his campaign account to his former chief of staff honestly it pains me to say because I like you personally Javier but you shouldn't be on thanks a lot you shouldn't be in this race you should be preparing your criminal defense [24:32] it Javier [24:34] talk about your chief of staff who said that you knew about these payments let's talk about [27:23] in the polls I think I get [34:30] no instead of forcing housing into places that don't want it we need to build housing in the places that do want it and I'm afraid all this conversation around housing we're not thinking big enough it's all just fiddling around the edges it's a crisis here in California so many young people I see they've given up on the idea that they could ever own their own home we need to build outwards not just upwards with apartment building shoved into suburban neighbors you know that only 6 % of our land is developed in California we could increase that to 7 % and there would be room for 10 million households and single -family homes so that young families could see their kids play outside in California we need to think big again back to the days when we used to build amazing things in California the suburbs of Southern California the state water project we should be thinking about how we store the ambition the abundance of California [41:20] believe a word he's saying his party increased those regulations mr. [47:06] yeah and we need to have common sense on climate change not ideology that ends up being counterproductive and exactly as Chad said hurting every small business and family and everyone in California I'm an environmentalist we love our beautiful natural landscapes our climate here in California we've got to protect that clean air clean water of course that's right but look at some of the things that we're doing in the name of climate change the wildfires that occurred in the Sierras in 2020 because the forests weren't managed properly the co2 emissions from that one year of mega wildfires wiped out all the savings from climate policy in the previous 20 years look at what's going on with our gas prices the highest in the country because instead of getting oil and gas from our own oil production here in California we are shipping it 7 ,500 miles in giant super tankers spewing out carbon emissions in the name of climate we are increasing carbon emissions we need some common sense here [48:55] a [49:54] look I don't know if you know how many EVs are on the roads in California the proportion the idea that that's gonna actually half of the [50:10] number man statewide yeah [50:13] do you know [50:14] it's another percentage of our vehicles on the roads [50:19] 7 % and he wants and it's power our power grid with that it's a lot of batteries this is what you get tell me the math on the batteries thank you you get from ideologues who are not actually it's actually called innovation [50:33] very much how we fix things how to make things work [58:01] Yes. We have to lower gas prices. [58:15] No. [69:28] We need to make it easier for working -class Californians to get into the UC system. As we used to, the costs are so high, the structure of the courses, all of this needs to change. I don't believe in artificial caps and regulation. That's the kind of policy that has got us into this mess. And I have to say, listening to my Democrat friends here, talking about education, it's as if they haven't been in charge for the last 16 years. They are the policies that they support that have got us to a position where less than half the kids in our schools can read at grade level. For math it's 35%. We need new management in this state if we're going to turn things around. We can't have more of the same. We need to make sure we use phonics to teach kids to read. Make sure that they can read by third grade. And like Mississippi does, not go to fourth grade if that doesn't happen. We need to hold teachers accountable also to make sure that we reform the pensions because right now 10 and a quarter percent of every teacher's salary is going towards their pension. We need that to change as well. [73:37] This is not about abortion rights. This is about one state trying to undermine another state's laws. We have a federal system. Yes or no, Mr. Hilton? Sorry? [73:47] Yes, I would follow the law, and that's because we have a constitution in this country that we need to [73:56] abortion rights. Mr. Steyer? It is about abortion. No, it isn't. [73:59] Undermine democracy in another state. Thank you, Mr. Hilton. The people in that state chose differently to California. [74:07] interfere in another state's laws in that way? Mr. [74:12] don't want Louisiana dictating our laws. We shouldn't be dictating Louisiana. Maybe you ought to run for governor. Mr. [74:22] Hell no. [74:56] I'm afraid it's not as simple as that. It really isn't. No, I'm serious. This is exactly the reason we get in. This [75:04] it's not the right way to discuss a very important and serious issue. Do you think there should be more safeguards on AI bots that interact with children? No, I'm sorry. This is why we get into a problem in this country, because we go for these simplistic solutions. Thank you, Mr. Hilton. Mr. Steyer, do you have an answer for me? And it causes problems that are unintended. And we need to have a serious conversation about a very serious issue. We have to protect children, but do it in a sensible way that works. Look at these policies that are being implemented around the world. Okay, Mr. Hilton, I have to move forward. Like in Australia, they don't work. [75:37] It's really not. [75:51] Yes or no questions. They're a little bit longer. Sometimes. [77:08] This state is desperate for change. We cannot have another four years of one -party rule. We need some balance. The only choice for change, apart from myself, is Chad. [80:31] I think we get it, Tom. You're a billionaire. Congratulations. Look, I get on with Tom. I get on with everyone on this stage, and we're all here for the same reason. We love this state, and we want it to be the state that once again offers young people the opportunity to make your life here better than anywhere else in our country. The truth is that we've gone off track. We've got one party rule now for 16 years. The results have been such a disappointment. It is time for some balance. We need some balance in our system. No more one party rule. And the reason that I can make the change happen is precisely because I get on with people from all different backgrounds. I'm not an ideologue. I'm pragmatic. I'm a problem solver. Most of my career has been in business, but I have experience working inside of a government. Above all, I know how to work with people to make change happen. That's what we need in California. Common sense, practical ideas to turn things around and restore the California dream.