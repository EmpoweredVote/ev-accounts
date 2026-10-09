You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-voting-rights/labels/coder-2.json. Write JSON only, matching
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
snapshot_id: 52572e24-9035-50a6-93b9-7da27eb48c73
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan

Saved from https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan (rendered page text, built-in browser, 2026-10-07) POLICY EMERGENCY ELECTION COUNT ACCELERATOR PLAN ← POLICY ARCHIVE EMERGENCY ELECTION COUNT ACCELERATOR PLAN INTRODUCTION California should be able to conduct elections that are both secure and timely. Every legal ballot should be counted, but voters should not have to wait weeks to find out the outcome of an election. The state routinely mobilizes personnel and resources during emergencies. When election offices face massive post-election backlogs, California should do the same. By temporarily assigning qualified state employees, deploying rapid-response support teams, and funding expanded county operations, California can accelerate ballot processing, reduce delays, and provide voters with election results more quickly while maintaining the integrity and security of the process. California is the fourth largest economy in the world, and home of the technology industry that has so dramatically changed the world. When it comes to elections, it’s time we acted like it. Ultimately, California needs broader reforms to its election system. But in the short term, for the primary election of June 2nd 2026, we cannot continue with a process that leaves millions of voters waiting weeks for results. Governor Newsom should immediately issue an emergency Executive Order designed to bring ballot-processing backlogs to a close as quickly as possible, with the goal of guaranteeing complete and verified election results within 48 hours of the deadline for receiving mail-in ballots: final election results by 8pm on Thursday 11th June. If India can count over 600 million ballots in 24 hours, surely California can count a tiny fraction of that number in twice the time. A SYSTEM THAT ISN’T WORKING California’s election delays are not an isolated problem. They are yet another symptom of a government that has stopped delivering basic results. Californians have been promised a high-speed rail project that has barely begun after years of delays and billions of dollars in spending. State and local governments have spent billions addressing homelessness while encampments remain a visible crisis in communities across the state. Now California once again finds itself waiting weeks for election results after fewer than ten million ballots were cast. It is an extraordinary and unacceptable shambles. California has become a global laughing stock for its inability to conduct elections in an efficient, timely manner. Californians have been conditioned to accept delays that would be unacceptable in almost any other area of government. Elections should be secure, accurate, and timely. The fact that voters can wait weeks for final results is evidence that the system is not functioning as it should. This is not about counting fewer ballots or lowering standards. It is about basic governing competence, which has completely collapsed in California, it now seems. Voters deserve an election system that is both accurate and efficient. PLAN FOR CHANGE California’s election laws should be reformed to deliver faster, more transparent, and more trustworthy election results. The following reforms would dramatically accelerate election results while preserving election integrity: Require vote-by-mail ballots to be received by Election Day rather than accepted for several days afterward if postmarked by Election Day. Mail ballots only to voters who specifically request them rather than automatically sending ballots to every registered voter. Provide free voter identification cards to all registered voters and require identification for in-person voting. Expand pre-election ballot processing so counties can verify signatures, prepare ballots for tabulation, and complete administrative review before Election Day. None of these reforms would eliminate the need to count every legal ballot. But together they would dramatically reduce post-election delays, improve transparency, strengthen confidence in the process, and move California toward a system where voters know the outcome of elections in hours, not weeks. EMERGENCY ELECTION COUNT ACCELERATOR CORPS While broader reforms are implemented, Governor Newsom should act immediately to accelerate the count in the primary election of June 2026. The Governor should establish an Emergency Election Count Accelerator Corps by temporarily deploying available state employees from non-essential administrative positions to county election offices experiencing significant ballot-processing backlogs. These personnel would work under the supervision of county Registrars of Voters and assist with ballot processing, administrative review, data entry, ballot preparation, and other support functions permitted under existing law. The state should also create regional election surge teams that can be rapidly deployed to counties facing the largest backlogs, ensuring staffing resources are directed where they are needed most. In addition, California should establish an Election Count Accelerator Fund to reimburse counties for overtime, expanded shifts, weekend operations, and other temporary costs associated with accelerating ballot processing after Election Day. The proposal would not change election laws, security procedures, or vote-counting standards. Every ballot would still be processed according to existing law and under the authority of local election officials. The goal is simple : count every legal ballot , maintain election integrity , and deliver timely results that voters can trust . Specifically , ensure that in the primary election of June 2026, Californians have complete and verified results within 48 hours of the deadline for receiving mail – in ballots . Final election results by 8 pm on Thursday 11 th June . ← Back to all policies

---
snapshot_id: 6e27fc75-f2b3-5189-9c73-2b42b0e8d6b7
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california

Saved from https://stevehiltonforgovernor.com/policies/a-modern-wildfire-prevention-plan-for-california (rendered page text, built-in browser, 2026-10-07) POLICY A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA ← POLICY ARCHIVE A MODERN WILDFIRE PREVENTION PLAN FOR CALIFORNIA Steve Hilton’s Plan to Stop Wildfires Before They Become Disasters THE PROBLEM Wildfires are no longer rare emergencies in California. They are a permanent threat. Every year, families lose their homes, communities are torn apart, insurance becomes more expensive or disappears entirely, and billions of dollars are spent reacting after the damage is done. We grieve, we rebuild slowly, and then we wait for the next one. This is not inevitable. Fire is part of California’s natural environment. Catastrophic fire is not. The scale and frequency of today’s disasters are the result of human choices, policy failures, and a system built around reaction instead of prevention. California does not lack firefighters, courage, or money. What we lack is a serious prevention strategy. WHY THE CURRENT APPROACH ISN’T WORKING California’s wildfire policy is reactive by design. It is built to mobilize after catastrophe, not to prevent it. That design did not happen by accident. It is the product of one-party Democratic rule in California, which has dominated state government for more than a decade and shaped how wildfire policy is written, funded, and enforced. Under Democratic control, the state has: Prioritized emergency reactivity and press conferences over long-term prevention. Made forest and brush management slower, more expensive, and harder to do through permitting, lawsuits, and extremist environmental regulation. Failed to deploy modern early detection systems, even as the technology has become affordable and reliable. Diverted fire spending towards growing government programs instead of reducing risk on the ground. Left homeowners and communities to navigate fire hardening on their own, with little support and lots of red tape. Allowed insurance risk to grow unchecked instead of reducing it through prevention. The system rewards reaction and paperwork. It punishes prevention. As a result, California has built a wildfire policy that looks busy but does not actually reduce risk. Fires keep getting bigger, more destructive, and more expensive even as spending keeps rising. That is what Democrat one-party rule produces: more bureaucracy, more process, more spending, and worse results. THE PLAN As governor, Steve Hilton will flip the model from reaction to prevention, making California the first place in the world where wildfire prevention is universal, modern, and proactive. Statewide Detection and Technology Deployment. Deploy modern detection and suppression technology statewide and reform procurement and regulatory rules so California can actually use and scale these tools quickly. A Modern Fire Force. Create a focused California Fire Force dedicated to early detection, rapid suppression, and deployment of modern technology including drones, automated systems, and advanced monitoring. End the Regulatory Barriers That Make Fires Worse. Roll back and reform extreme environmental and air quality regulations that have been weaponized to block basic fire prevention and firefighting. This includes fixing harmful air quality bureaucracy that has been used to stop controlled burns, reforming endangered species rules that prevent effective vegetation management and emergency response, and restoring common-sense authority for fire agencies to act. This will be achieved through executive orders and appointments of serious, results-driven leadership to key agencies like CARB, the Santa Monica Mountains Conservancy, and related regulatory bodies. Universal Fire Protection for Homes. Every home in a fire risk zone becomes eligible for state-supported fire prevention treatments. This is not a mandate. It is an incentive-driven system that makes prevention easy, affordable, and normal. These treatments include fire-retardant coatings for vegetation, decks, fences, and structures; ember-resistant upgrades and defensible space treatments; and modern non-toxic fire suppression and retardant technologies. Align Insurance With Prevention. Reform insurance regulation so insurers can and must offer meaningful premium discounts for fire-hardened homes and co-fund prevention programs, because preventing losses costs less than paying for disasters. Reward Fire Safety. Provide property tax credits for homeowners who complete certified fire prevention upgrades and streamline permits so people can protect their homes quickly. Fix Emergency Readiness and Response. Launch an immediate and comprehensive review, reporting within 90 days, of fire and emergency response capacity in high-risk counties and major cities to ensure the devastating failures exposed in Los Angeles under Mayor Karen Bass never happen again. This includes reviewing water availability and infrastructure, including reservoirs and hydrants, equipment readiness, personnel deployment, and inter-agency coordination. Steve Hilton will appoint an Emergency Preparedness and Response “A Team” of world-class professionals to lead this effort and set new statewide standards for readiness, coordination, and accountability. Open the Door to Innovation. Reform state procurement rules so California can actually use modern detection, suppression, and prevention technologies instead of blocking them with bureaucracy. This plan is informed by the work of Rick Crawford, former Los Angeles Fire Department Battalion Chief, whose California All-Risk Governance Doctrine documents the leadership, infrastructure, and coordination failures exposed by the Palisades Fire. His analysis reinforces the need to shift from reactive response to permanent, accountable readiness before the next disaster strikes. WHAT THIS WOULD MEAN FOR CALIFORNIANS Fewer fires would become disasters because early detection and suppression would stop fires while they are still small. Homes would be safer because fire-hardened properties would be far more likely to survive. Insurance would become affordable again because lower risk would mean lower premiums and more insurers willing to operate in California. Communities would be more stable with fewer evacuations, fewer rebuilds, and fewer families displaced. Taxpayer money would be spent smarter, because prevention costs a fraction of emergency response and rebuilding. Together, these changes would restore something Californians have lost: confidence that their government is actually working to keep them safe. ← Back to all policies

---
snapshot_id: 0aca1683-3fd4-501d-96c9-0a53cae6ce34
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/build-a-real-california-state-police-force

Saved from https://stevehiltonforgovernor.com/policies/build-a-real-california-state-police-force (rendered page text, built-in browser, 2026-10-07) POLICY BUILD A REAL CALIFORNIA STATE POLICE FORCE ← POLICY ARCHIVE BUILD A REAL CALIFORNIA STATE POLICE FORCE Paid for by cutting Newsom’s bureaucracy, not by overcharging California drivers OVERVIEW California needs more police officers on the streets. Criminal networks operate across city and county lines, and local police and sheriffs cannot be expected to take them on alone. Steve Hilton will turn CHP into a real California State Police Force and give it the manpower and resources to help keep the entire state safe. He will pay for it by cutting the bureaucracy Gavin Newsom built, not by raising taxes or piling more charges onto California drivers. THE PROBLEM CHP is not just traffic cops. It protects state buildings and critical infrastructure, investigates crimes that cross jurisdictions, responds to disasters and works alongside local law enforcement. California’s former State Police was merged into CHP in 1995. The statewide role already exists. CHP has never been built to match it. CHP has around 6,600 sworn officers and an annual budget of about $3.3 billion. That is not enough when organized theft crews, drug traffickers, human traffickers and other criminal networks are operating across the state. Then there is the way California pays for CHP. More than $3.1 billion of its budget comes from the Motor Vehicle Account. The main source of money for that account is vehicle registration fees. Drivers are bankrolling a statewide police force every time they renew their registration. That is ridiculous. CHP works for every Californian. Its budget belongs in the General Fund. Meanwhile, Gavin Newsom’s first budget proposed 215,821 executive-branch positions. His latest proposes around 251,000. He added more than 35,000 state positions while California’s population declined. That tells you everything about the priorities of the people running this state. STEVE’S PLAN 1. GROW CHP TOWARD 10,000 OFFICERS Steve will increase CHP’s annual budget to $4 billion and build the force toward 10,000 sworn officers. This will be phased in as new officers are properly recruited and trained. CHP will continue to keep the highways safe while taking on organized crime, trafficking and other threats that cross city and county lines. Police chiefs and elected sheriffs will remain in charge of local policing. CHP will be a force multiplier, helping local departments with major investigations, specialized capabilities and backup when they need it. 2. STOP USING CAR REGISTRATION AS A CASH MACHINE Steve will move CHP funding out of the Motor Vehicle Account and into the General Fund. This is essential to his Califordable plan to abolish the stand-alone DMV and cut annual vehicle registration to a flat $73. That fee will pay for secure vehicle records and the actual cost of administering registrations. That’s it. Drivers will no longer be forced to fund a statewide police force through excessive registration charges. 3. CUT NEWSOM’S BUREAUCRACY AND PAY FOR POLICE Steve will return executive-branch headcount to its pre-Newsom level. That goes beyond the minimum 10 percent bureaucracy reduction in Operation Zero Waste. Frontline public safety and essential services will be protected. The cuts will fall on the administrative and management bloat Newsom built. CHP will grow within the lower overall state headcount because bureaucratic positions will be cut more deeply. At current salary and benefit costs, returning to the pre-Newsom headcount will save roughly $5 billion a year. Enough to give CHP a $4 billion General Fund budget and start hiring the additional officers California needs. The money is there. Gavin Newsom spent it building a bigger bureaucracy. Steve will use it to put more police officers on the streets. Sources: California Legislative Analyst’s Office analysis of the CHP budget and Motor Vehicle Account; California Highway Patrol staffing; California Department of Finance workforce schedules for 2019-20 and 2026-27. ← Back to all policies

---
snapshot_id: 71345f19-5af3-5ebb-8487-c81c154f58d4
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/fourth-largest-economy-month-long-vote-count-hilton-calls-on-newsom-to-implement-emergency-action/

Fourth-Largest Economy. Month-Long Vote Count. Hilton Calls on Newsom to Implement Emergency Action - Steve Hilton for Governor Skip to content ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate ","library":"fa-solid"},"toggle":"burger"}" data-widget_type="nav-menu.default"> Home Meet Steve Vision for California Get Involved Policies Store Home Meet Steve Vision for California Get Involved Policies Store Donate Fourth-Largest Economy. Month-Long Vote Count. Hilton Calls on Newsom to Implement Emergency Action Share This June 5, 2026 7:14 pm STEVE HILTON UNVEILS EMERGENCY ELECTION COUNT ACCELERATOR PLAN Calls on Newsom to End California’s Election Shambles and Deliver Final Results by June 11 SAN MATEO, CA — Steve Hilton today unveiled his Emergency Election Count Accelerator Plan, calling on Governor Gavin Newsom to immediately mobilize state resources to bring California’s election counting chaos to a swift conclusion and deliver complete, verified election results by 8:00 p.m. on Thursday, June 11. California is the laughing stock of America when it comes to counting votes. In the home of Silicon Valley, government officials need a month to count fewer than 10 million ballots. India counts more than 600 million in one day. “Another election. Another failure,” Hilton said. “California can put satellites into space, build world-changing technology, and power the global economy, but somehow, the government can’t tell voters who won an election without making them wait weeks. We can’t go on like this.” Hilton’s proposal calls on Governor Newsom to immediately establish an Emergency Election Count Accelerator Corps by temporarily assigning available state employees from nonessential administrative positions to county election offices facing significant ballot-processing backlogs. Under the proposal, personnel would work under the supervision of local election officials and assist with ballot processing, administrative review, data entry, ballot preparation, and other support functions permitted by existing law. The plan also creates regional election surge teams that can be rapidly deployed to counties with the largest backlogs and establishes an Election Count Accelerator Fund to reimburse counties for overtime, expanded shifts, weekend operations, and other temporary costs incurred to accelerate ballot processing. Importantly, the proposal does not change election laws, security procedures, or vote-counting standards. Every legal ballot would still be counted in accordance with existing law and under the authority of local election officials. “This is not about counting fewer ballots or lowering standards. It’s about basic governing competence,” Hilton said. “The people running California have conditioned voters to accept failure as normal. They waste billions on projects that never get built. They spend billions on homelessness while the problem worsens. And now they expect Californians to accept waiting a month for election results as if that’s normal, too. It isn’t.” Hilton noted that California routinely mobilizes personnel and resources during wildfires, floods, and other emergencies. Election offices facing massive ballot-processing backlogs should receive the same level of support as well. The goal is simple: count every legal ballot, preserve election integrity, and deliver timely election results that voters can trust. “Californians deserve elections that are secure, transparent, and timely,” Hilton said. “If Governor Newsom is serious about restoring confidence in our elections, he should stop making excuses and deploy resources. Let’s get this done and give Californians the results they deserve.” Press Conference Video Election Counter Accelerator Plan Share This Steve Hilton For Governor X-twitter Instagram Facebook Youtube Paid for by Steve Hilton for Governor 2026 By entering your phone number and selecting to opt in, you consent to receive SMS/MMS marketing and polling text messages, donation requests, updates, and other important information to that number from Steve Hilton for Governor. Msg&data rates may apply. Msg frequency varies. Reply HELP for help or STOP to opt-out at any time. SMS information is not rented, sold, or shared. View Privacy Policy and Terms & Conditions. To make a donation by check, please send your contribution to: P.O. Box 730 Hilmar, CA 95324 Press Inquiries ONLY: [email protected] Copyright &copy; 2026. Steve Hilton for Governor. All Rights Reserved Campaign News Contact Privacy Policy

---
snapshot_id: 56ace4f9-4855-531a-80d4-8a620d5c0a45
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: 4b95aa7f-95aa-5da3-9913-3cd69045b4ac
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/healthy-food-for-kids

Saved from https://stevehiltonforgovernor.com/policies/healthy-food-for-kids (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA THE WORLD LEADER IN HEALTHY FOOD FOR KIDS ← POLICY ARCHIVE MAKING CALIFORNIA THE WORLD LEADER IN HEALTHY FOOD FOR KIDS STEVE HILTON’S PLAN FOR HEALTHY CALIFORNIA FOOD IN SCHOOLS OVERVIEW California is the food capital of America. California grows it. California pays for the meals. Yet too often California kids are fed ultra-processed junk trucked in by giant out-of-state food-service companies. That is insane. California already guarantees free breakfast and lunch to every student who wants one. Now it should guarantee that at least one of those meals is fresh, healthy, and 100% California-sourced. As governor, Steve Hilton will build on the great progress that has been made under Gavin Newsom, including efforts spearheaded by Jen Newsom, to make this vision a reality. Programs like Farm to School and the KIT program (Kitchen Infrastructure and Training) provide a strong foundation. Now we need to finish the job and bring these benefits to every school district, every school, every student, every day. We are the richest state in the richest nation on earth, with the most fertile farmland and best, most innovative agriculture industry on the planet. We grow the healthy food that we should want people to be eating: produce, fruit, nuts. Our tax dollars should be supporting both the health of our children and the health of our ag industry and our farmers, many of whom have been working the land here for generations but are now struggling thanks to bad policies on water, energy and labor regulation. There is no reason why California shouldn’t be the undisputed world leader in healthy, local food for kids. Decades ago, Alice Waters in Berkeley sparked a global food revolution - simple, fresh, local, seasonal - and with her Edible Schoolyard movement led the way for the revolution to embrace our schools as well. Now there must be no excuses and no delay. No state money for ultra-processed food. No giant food-service company getting state contracts to serve out-of-state food or junk. And every child should get the chance, the knowledge, and just as importantly the time, to grow, cook, eat and understand real food. THE PROBLEM California schools will serve nearly one billion meals this year. That is enormous buying power. California produces the food that nourishes America: nearly half the nation's vegetables and more than three-quarters of its fruits and nuts. So why are California kids not eating it? Why are California tax dollars flowing to huge industrial food-service companies whose business model is food made for shelf life, not health? Why are parents checking every ingredient while California farms can grow almost everything a child needs to eat well? Jennifer Siebel Newsom has done fantastic work championing the Farm to School program. It is exactly what we need, and now should be expanded and extended. Corollary programs like KIT (School Kitchen Infrastructure and Training) and of course School Meals for All should work in closer harmony, with greater reach. The Newsoms have also begun the vital work to get ultra-processed food out of school meals. But the law does not fully take effect until 2035. A child starting kindergarten today could graduate before the job is done. Childhood obesity, anxiety, diabetes, and chronic illness should not wait for another decade of reports and roll-outs. California should be the good food capital of America and indeed the world. It is absurd that this is not already true in California schools. WHAT STEVE WILL DO A HEALTHY CALIFORNIA MEAL IN EVERY SCHOOL, EVERY DAY Every school will serve a healthy meal every day that is 100% California-sourced. Not occasionally. Not only in districts with a grant writer. Every day. Steve will build on Farm to School but set one standard for the whole state: food grown, raised, or made in California. This would be a massive win not only for our children but for our great farmers and ranchers in California. Steve will lead a new effort to tighten up and enforce definitions, to track the food that ends up in our schools, and reject any federal regulations or procurement rules that stand in the way of California’s ambition. (Of course there will be a very small number of food items that cannot be 100% California-sourced, and such limited exceptions will be permitted.) NO CALIFORNIA TAX DOLLARS FOR ULTRA-PROCESSED FOOD Steve will end California state spending on ultra-processed food for children. This has already been legislated but as so often in California, is not properly implemented or enforced. One of the barriers is the lack of an agreed-upon definition. As governor, Steve will fast track the definition and the ban, prioritizing the voices of families, farmers and health professionals, not the Big Food lobby. And in order to fully implement the ban on Ultra-Processed Food, we also need to fast-track fresh food preparation infrastructure and training. PUT CALIFORNIA FARMERS FIRST Steve will end state contracts with giant industrial food-service providers that use ultra-processed food or food from out of state to feed California children. California will use its buying power to support California farmers, ranchers, fishers, food makers, and regional kitchens. California grows it here. California should serve it here. Steve will work with the federal government to make sure there are no barriers to full implementation and funding. And Steve will work directly with farmers and their representative organizations to create close partnerships for direct sales to schools and other state-supported institutions, ensuring both a guaranteed California market and a better price. AN EDIBLE SCHOOLYARD AT EVERY SCHOOL Alice Waters’ pioneering Edible Schoolyard initiative is a beautiful and practical example of how creative thinking can transform attitudes to food and nutrition, as well as teaching valuable life skills. The Edible Schoolyard concept teaches children how to grow food, cook and prepare fresh, healthy meals, and inform their wider education through food. It’s also about time and human connection: taking the time to sit down and eat a meal together is such an important part of our lives that is being squeezed in a world of convenience and delivery apps. If we can foster food and meal-centered wellbeing at school, it would be a tremendous benefit to our society. As governor, Steve will push for a culture in schools that prioritizes food, food education and proper time to eat together. Specifically, the goal will be to see some form of Edible Schoolyard project in every school, adapted to the space it has. Children should have the chance to grow food, taste food, learn to cook it, and understand the connection between a healthy meal and a rich, healthy life with strong human relationships. PARTNERSHIPS WITH LOCAL RESTAURANTS AND CHEFS Another massive untapped resource for the goals laid out in this paper are our great local restaurants and chefs. They have so much to offer, not just in the school setting but including opportunities for work experience, skills training and personal development. Steve will work with restaurants, chefs, and their professional and representative organizations to foster ties between local restaurants, chefs - whether working or retired - and local schools. GOOD FOOD CAPITAL OF THE WORLD California does not need another program with a nice name and a stack of press releases. It needs a governor who sets a clear goal and helps make it happen in a hands-on, practical way. Healthy, California-sourced food in every school, every day. California: the good food capital of the world, in every way. That is the promise. ← Back to all policies

---
snapshot_id: 5c5d1dc6-d62c-5501-9dd5-dad2cc929473
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD ← POLICY ARCHIVE MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD THE PROBLEM California should be leading the future of digital finance. Instead, we are driving innovation, investment, and talent out of our state. For decades, California was the best place in the world to build transformative technologies. Today, companies and entrepreneurs are increasingly looking elsewhere because of overregulation, political uncertainty, and rising costs. The global race for leadership in digital assets and blockchain technology is already underway. States like Texas and Wyoming, along with other countries, are competing aggressively for jobs, investment, and innovation. California has every advantage needed to lead, but bad policy decisions are pushing that opportunity away. Digital assets, blockchain networks, and stablecoins are becoming an important part of the future of finance and payments. If California falls behind, America falls behind with it. WHY THIS IS HAPPENING California’s leadership has adopted a “regulate first, figure it out later” approach to innovation. Instead of creating clear rules that encourage responsible growth, policymakers have created uncertainty that drives companies and investment elsewhere. Companies should not have to guess what the rules are before they invest and build here. California has already seen what happens when government makes it too difficult to build, invest, and innovate. We should not repeat those mistakes with one of the most important emerging technologies in the world. THE PLAN 1. CREATE CLEAR RULES FOR DIGITAL ASSETS California should provide transparent and predictable rules for digital asset companies instead of overly broad regulations that create confusion and drive investment elsewhere. California should clean up the Digital Financial Assets Law and ensure state rules complement emerging federal frameworks instead of conflicting with them. 2. PROTECT PARTICIPATION IN THE DIGITAL ECONOMY Californians should be free to securely control their own digital assets and lawfully participate in blockchain networks without unnecessary government interference. California should end its misguided restrictions on staking and allow Californians to participate in lawful staking services. 3. SUPPORT BLOCKCHAIN INNOVATION AND KEEP CRYPTO JOBS IN CALIFORNIA California should be the best place in the world to build crypto companies and blockchain technology. We should lower barriers to building and stop driving companies, investment, and talent to other states and countries. 4. PROTECT CONSUMERS AND CRACK DOWN ON FRAUD Government has a responsibility to aggressively prosecute scams, fraud, and criminal abuse. But enforcement should target bad actors, not crush legitimate innovation and responsible companies. CONCLUSION California became successful because we built the future instead of fearing it. We have the talent, entrepreneurs, and companies needed to lead the world in digital assets and blockchain technology. But leadership requires a governor who supports growth, encourages innovation, and creates clear rules instead of uncertainty and bureaucracy. Instead of driving opportunities away, California should be the place where the future is built. ← Back to all policies

---
snapshot_id: 405e9eb5-cf8c-5718-995d-a9d0792715c6
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/abolish-the-dmv

Saved from https://stevehiltonforgovernor.com/policies/abolish-the-dmv (rendered page text, built-in browser, 2026-10-07) POLICY ABOLISH THE DMV ← POLICY ARCHIVE ABOLISH THE DMV A CALIFORDABLE Plan to Cut Vehicle Registration to $73, End DMV Lines, Eliminate Bureaucracy, and Turn Empty Offices Into Opportunity OVERVIEW California is a car state. For most people, a car is how they get to work, get their kids to school, run a business, and live their lives. Yet something as basic as renewing a registration can still mean taking time off work to deal with the hated DMV. California spends $1.46 billion a year on a department with 170 field offices. It is a huge, old-fashioned monopoly that treats the taxpayers who fund it with complete contempt. It is the miserable symbol of California's bloated, costly nanny state bureaucracy, bossing people around while charging a fortune for the privilege. The DMV has trained people to expect delays, confusing paperwork, and bad service. Most states do not have a stand-alone DMV - California is one of only ten or so states with a separate DMV bureaucracy. Of course it is important that the state has secure records, legitimate licenses, and strong fraud prevention. It does not need to make people stand in line all day to receive rude, surly - and insanely slow - service for things that in other countries and states are handled entirely online. Steve Hilton will abolish the DMV, set annual vehicle registration at a flat $73, and give Californians better, cheaper options. THE PROBLEM The DMV is built around the bureaucracy, not the public. If a transaction cannot be completed online, Californians have to fit it into the state's schedule. They take time off work, arrange child care, miss appointments, and hope the person behind the counter can solve the problem that day. If the service is slow, confusing, or unhelpful, there is nowhere else to go. The DMV has a monopoly. For years, Democrats have tried to patch this failure with another website, another kiosk, another appointment system, or a new set of office hours. None of that fixes the basic problem. The public is still expected to work around the government instead of the government working around the public. And California’s basic $73 vehicle registration fee is buried under a value-based vehicle tax, transportation add-ons, and local surcharges. Drivers can end up paying $500, $600…even $1,000 or more, while in most other states, registration is under $100. California already uses kiosks and private partners for some transactions, but the better option can come with an additional fee. People who can afford it sometimes buy their way out of the line. Everyone else is stuck. Other states have shown a better way. Colorado routes most title and registration work through county offices. Arizona allows regulated local providers to handle registrations, titles, driver's licenses, and road tests. California can do the same while keeping the state in charge of security and standards. STEVE HILTON'S PLAN: ABOLISH THE DMV The point is simple: get rid of the DMV bureaucracy and buildings, not the services people need. Steve Hilton's plan keeps the state responsible for secure records and safety, but gives Californians more convenient and affordable ways to get things done. 1. ABOLISH THE DMV AS A STAND-ALONE DEPARTMENT Steve will order a full audit of every DMV function, office, lease, contract, and cost. It will report within three months. He will then send the Legislature a No More DMV Act to eliminate the Department of Motor Vehicles. The state will keep a lean records and safety operation within existing government. Its job will be to maintain the statewide database, issue state credentials, protect personal information, investigate fraud, and enforce safety rules. It will not run a giant network of public waiting rooms. The goal is a much smaller state back-end that does the work only government must do. 2. MAKE DMV SERVICES LOCAL AND CUT REGISTRATION TO $73 Routine title, registration, plate, and renewal transactions will move to county offices and certified local service centers. Californians should be able to handle basic vehicle business where they already live and work, not only at a DMV field office. Steve will restore car registration to what it should have been all along: a flat $73 annual fee for every vehicle. He will strip out the value-based vehicle tax, transportation add-ons, local surcharges, and other stacked charges that turn a basic service into a hidden Car Tax. Registration should cover the cost of administering registrations. It should not be used as a revenue source. Qualified public and private service centers will also be able to handle driver's-license and identification-card transactions, including testing, when they meet state and federal standards. The driver's license or vehicle title will still be state-issued. The difference is that people will no longer have only one government office to rely on. The ordinary registration option must be available for the flat $73 fee. Californians should not have to pay extra just to avoid a DMV line. Local centers may offer clearly labeled premium services, such as after-hours appointments, but the ordinary option must remain affordable. No field office will close until people in that area have an equal or better in-person option. Rural communities will have mobile service where a permanent location is not practical. 3. KEEP THE SYSTEM SECURE AND HOLD PROVIDERS ACCOUNTABLE Every county office and certified service center will connect to one secure state system, use the same identity-verification rules, and follow the same recordkeeping standards. California will continue to meet REAL ID requirements and commercial-driver rules. As separately announced, CDLs will no longer be issued to foreign nationals who don’t speak English. Any organization trusted with a public function must earn that trust. Service centers will face strict requirements for training, background checks, data security, accessibility, record accuracy, and customer service. The state will conduct random audits, investigate fraud, publish performance results, and revoke certification from providers that cut corners or treat people badly. The public should never be trapped with poor service because one government office has a monopoly. 4. TURN UNNEEDED DMV OFFICES INTO OPPORTUNITY Steve will publish an inventory of every DMV lease and state-owned property. Unneeded leases will not be renewed. For suitable state-owned sites, local community colleges, registered apprenticeship programs, and employer partnerships will get the first opportunity to turn former DMV offices into after-school clubs that serve as skills and job-training centers. The focus will be on training that leads directly to work in each community: construction trades, electrical work, HVAC, welding, health-care support, logistics, commercial driving, water and energy infrastructure, and advanced manufacturing. A local operator must be responsible for the program and report real results, including completion, job placement, and wage gains. If there is no practical public use and no credible local training partner, the property should be sold. 5. CUT COSTS AND KEEP REGISTRATION AT $73 California spends $1.46 billion a year on the DMV. That is too much money tied up in an outdated department that gives people a bad experience. Ending unnecessary leases, shrinking the state back office, eliminating redundant overhead, and using competitively selected local service centers will reduce the cost of providing driver and vehicle services. Every contract will be measured against the current cost per transaction. If a provider cannot deliver better service at a lower cost, it will lose the contract. The new state operation will publish its full operating cost, average cost per transaction, and annual savings. Net savings will go first to keeping vehicle costs down, including the $73 flat registration fee. The $73 fee will be exactly that: a fee, not the starting point for another stack of taxes and add-ons. If this reform does not save money and lower what people pay, it is not a reform. Capping vehicle registration at $73 per vehicle per year will reduce revenue from about $11 billion to $2.7 billion. Spending will be reduced proportionately as part of Operation Zero Waste. One essential change: getting better value for money for spending on roads. It is estimated that it costs four times as much to build the exact equivalent section of road in California compared to other states, like Texas - that actually rank higher than California on road quality. CONCLUSION California does not need a better DMV line. It needs no DMV line. Steve Hilton's plan keeps the records secure, keeps safety rules in place, puts registration back to a flat $73, and gets rid of the bureaucracy that wastes people's time and money. Californians should be spending their time getting to work, getting home, and getting ahead, not waiting for the government to let them move on with their day. The DMV is the symbol of California’s bloated, costly and counter-productive nanny state bureaucracy that treats citizens and taxpayers with contempt. The vast majority of states do not have a stand-alone DMV. It is time to put California’s DMV out of its misery. ← Back to all policies

---
snapshot_id: 026515d7-8c23-5a38-93bc-a0165086623f
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:14] >> Are we ready to save our beautiful state of [0:37] >> Democracy is under threat. >> Everyone agrees we need change. That's what I'm fighting for. [1:17] >> We can turn things around. You just have [7:39] >> So Caitlyn and Alex, it's interesting. We've already seen a couple of things that we'll probably see a lot of in this debate, which is the Democrats who are here who've been responsible for 16 years of one party rule for everything that we see in California won't take responsibility and all they can talk about is Trump. Look, I was asked how I'm preparing for this debate the other day. And my answer was the meetings, the thousands of people that have come to our events the last year in California. I've traveled to every part of the state. I've seen the struggle and the stories and that is my struggle and my stories. My parents were immigrants. The California dream is my dream and I want that for every single one of you watching out there. We can get it [8:39] >> So, they should vote for the candidate who's got a concrete plan to make our state calffordable. $3 gas, cut your electric bills in half, your first hundred grand taxfree, a home you can afford to buy. It's common sense, practical things. Most of my career has been in business. I know how to get things done. And we need to change. We need some fresh thinking. after 16 years of one party rule from these Democrats that have given us the highest poverty rate as you mentioned the highest unemployment rate and the highest cost of living in the country. [10:06] ahead. >> It's not Donald Trump who's given us gas prices $2 higher than the rest of the country. It's Democrat policies, which Antonia and all the Democrats here support. It's not Donald Trump that's given us the highest housing costs in the country. It's Democrat policies that all these Democrats support. Donald Trump is the president in all the other states of America where the cost of living is way lower than in California. Obviously, it is way past time for change in California and endlessly going on about Donald Trump doesn't serve the needs of the struggling families and small businesses. >> Can you say whether or not he won the election? [14:23] Hilton. >> So, so Matt says that it's obviously impossible to get to $3 gas. Um, as I have laid out in my plan, before the Iran war, there were 40 states in America with $3 gas or lower, most of the which don't have the abundant oil reserves that we have in California. But because of the policy supported by Matt and all these Democrats, we are now shipping oil halfway around the world, 7,500 miles from places like Iraq instead of opening up California oil and gas production so we can reduce costs and get $3 gas in California, which is my plan. [15:00] >> Secretary Bera. [24:05] >> It is. There's there's a very simple truth uh which everyone in California knows which is that taxes are too high and we need taxes to be lower and they're especially too high for working people in California. You got people on 70 80 90 grand in California which doesn't get you very far who are paying 9.3% state income tax. That is higher than the top rate in most other states. That's why my plan eliminates state income tax under 100 grand. And by the way, if you think that it can't get worse in California, I've got two words for you. Tom Styer. Under Tommy Styer, the taxes will be higher. Gas prices will be higher. Everything will be higher with Styer. [26:43] >> Thank you, [29:29] >> So I'm I'm the only immigrant on stage. I'm a legal immigrant and Americans support immigration when it is properly controlled. And what we saw under the Biden administration, open borders undermined everybody's support for immigration. And as governor, I've made it very clear although it is the federal government's responsibility to to um determine and implement immigration policy, I think it's important that all the laws are peacefully enforced. And as governor, I would make sure that we work with the federal government to enforce our laws. Expect [30:11] workers? >> The the policy on deportation is the exact same policy that we saw with President Obama. In fact, the numbers of deportations right now in our country and in California are slightly just to clarify your point. Can you answer the question? I answered the question which is I will work. >> Will you deport him? >> That was the question. >> Well, would you Antonia? Because the governor of California, as you know, doesn't make that decision. It is the president of the United States elected by the country. [34:43] >> I I don't want to respond to to silly name calling, but I'd like to actually respond to something Katie said, and I think it's probably a sincere policy um difference between us. She said something very revealing which is the only way really that California's economy has been growing in the last few years is through illegal immigration. And I just don't think that's the right way for us to be growing. I think we need to help small businesses create jobs and opportunity and for Californians to be able to earn more and live the California dream and for entrepreneurs to want to start businesses in California. That's how we should be growing our economy, not by [35:23] consequences of that decision, >> Katie, it's I there's a difference I think you'll accept between legal and illegal immigration. [43:18] Hilton, >> um Antonio mentioned uh me earlier and said I just recently arrived. It's true. I arrived here in 2012 with my wife and my two sons. But what's interesting is that um I don't think there's an appreciation of the difference between legal and illegal immigration. I've spent many many times right here in East LA where we are with legal immigrants with families of legal immigrants who really resent the unfairness that we're seeing in California where you have illegal immigrants who are getting free benefits, housing, welfare, and they say to me, "Look, we did it the right way. We worked hard. the right way. Candidates, don't worry. >> We are not getting fairness and we need to restore fairness in our [45:34] >> I think the next governor of California will have to work with the administration and with the president that the American people elected to get good results for Californians. And by the way, my attitude will be to work with the president regardless of party to get good results for Californians. Now, it so happens that we have a president who has endorsed me for governor, and we've discussed how I can work with his team to lower gas prices in California by opening up energy production, to reduce wildfire risk, by proper forest management, to get the fraud and the waste out of our state budget so we can cut taxes. These are all practical ways we can work together to help everyone. >> Thank you, Mr. California. [55:54] singlepayer healthcare. >> Just listen to these Democrats arguing about whether to go left or even further left when that's the direction that's got us into this mess, the highest cost, the highest taxes in the country. I'm the only person here with actual experience of singlepayer healthcare. Both as a patient and as a policy maker. As a patient, it nearly killed me. That's another story we don't have time for. As a policy maker, you end up with the worst patient satisfaction, cost that you can't afford, taxes skyhigh to pay for it. It is a total disaster. And the actual way we deal with health care in this state is to at least stop spending $20 billion a year on free health care for illegal immigrants who [64:17] Court has stopped you from being able to [64:21] that's a lie. My my view is that it's a bit rich for Javier to talk about following the law when he is mired personally in a corruption scandal where his former chief of staff Shan McCcluskey when Javier was appointed by Joe Biden to be health secretary he wanted his chief of staff to go with him. The salary wasn't enough. So what did they do? They took money from Javier's campaign account to top up his salary by funneling it to Dana Williamson, Gavin Newsome's former chief of staff, so that it was paid to this guy's wife. All of that is illegal. It is against state law. It's against federal law. My running mate for attorney general, Michael Gates, has this evening written to Javier Bera to make it clear that when he is attorney general, Javier will be investigated and if necessary, prosecuted for these crimes. [65:21] >> I'm not going to weigh in on something that I don't have the knowledge of the facts on. I trust that Chad is interested in what we should all be interested in, which is ensuring the integrity of our elections and restoring faith in our elections in California. That's why I support voter ID in California. Let's see what these Democrats think of voter ID. [66:24] chief And it was your decision. [66:29] Washington as health secretary and you wanted him by your side. And the reason that the money was transferred is because the salary wasn't high enough. That's why you engaged in this scheme which is [67:47] >> And just today, I launched a new plan for starter homes in California. One of the most heartbreaking things I see is young people, they come to our events and I asked them, "Do you ever see yourself owning a home in California, starting a family here?" And they say, "No, and we're going to have to leave." And that's why we've got to enact a very straightforward plan. Number one, we have to get rid of the regulations that make it two or three times as expensive to build the exact same home in California as in neighboring states. We have to stop the lawsuits filed by the unions who support these Democrats that get in the way of building housing. And to your point, we have to stop trying to force housing into suburban neighborhoods where people don't want it. Instead, we have to build single family homes in the places in our state that do want to expand. That's the plan to make sure that we can restore that California dream of home ownership. It is the heart of opportunity for our young people and it's being taken away by these Democrats and their policies. >> Mayor Mayanm, your response. [81:02] >> Mr. [81:04] Hilton, >> look, this is a very serious moment for California. The ballots are out. They're in your hands. And we have a really big choice to make, which is do we go for another four years of one party rule that's given us the highest taxes for the worst results, the highest poverty rate, highest unemployment rate, highest cost of living, serious policy questions, homelessness. We need to stop homelessness and end it. We need to stop funding fiascos like highspeed rail. We need to lift burdens on our business. That's what this debate needs to be about. And the only way to get the change we need is to [86:13] >> It's classic Democrats, isn't it? What you're hearing. Um, if it moves, tax it. If it still moves, regulate it. And if it stops, move it. I guess they want to subsidize it. Look, the truth is on this we have to have a bit of humility. This is a very fastmoving technology and actually even the people involved in it disagree about its exact consequences. Here are two things that we two practical things we could and should be doing better today. First of all, the real bluecollar jobs that are coming from the AI revolution, they're not happening in California. They're going to Texas and Arizona semiconductor manufacturing. We could get that back by removing regulations. And secondly, our school system is not educating our kids to be able to thrive in the world of AI. We need to [89:30] >> I think that was my word. Would you like [89:32] that charge? >> Again, I don't want to respond to silly insults, but I'll take the substantive point, which is first of all, when Tom talks about um uh tripling subsidies for electric vehicles, let's be clear what that is. That is higher taxes on hardworking Californians driving their gas, cars, and trucks every day so that Tom's rich friends can feel virtuous about saving the climate. The truth is, we need common sense on climate change. It doesn't make sense to import oil from halfway around the world, increasing carbon emissions in the name of climate. It doesn't make sense to allow mega wildfires in our forests that actually release more carbon dioxide than what is saved by all these climate policy. [96:06] Hilton. >> Um, so highspeed rail is an example of the fraud. Um, they've spent billions of dollars. I don't know where the money's gone. It certainly hasn't gone into building anything that actually works. And I just want to make one broader point about fraud. I'm actually running this race in a different way than we've seen before. I've put together a team to run with me. There are other statewide offices. And along with my running mate for state controller, Herb Morgan, and Michael Gates for attorney general, and Gloria Romero for Lieutenant Governor, we've actually been investigating the fraud. Our survey so far suggest that there in the last five years in California, we've had $425 billion dollars of fraud. That's around 80 billion a year, around 20% of the budget. And our team is going to stop it and prosecute it and give money. [96:54] >> real quickly, mayor. [99:59] I guess that would be a good one. [100:00] Clint Eastwood. >> Okay. Mr. Hilton. >> I think there's only one choice really. Jason [102:45] rest of the state? Well, um, if you ask my wife and my sons, often to their great embarrassment, it's that I absolutely hate bureaucracy and ridiculous, pointless rules and regulations that crush the life out of uh, people and businesses and daily experience that we have. And so, I just want to tell everyone, I'm going to be relentless, absolutely relentless in fighting the nonsense that makes life so difficult for each and every one of you. I will not rest until we restore sanity to our beautiful state of