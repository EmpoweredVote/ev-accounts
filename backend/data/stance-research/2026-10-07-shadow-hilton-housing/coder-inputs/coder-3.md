You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-housing/labels/coder-3.json. Write JSON only, matching
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

### topic_key: housing
topic_id: 669cac97-66a6-4087-b036-936fbe62efb3  served_revision_id: 598c879d-f387-461c-9120-fbbbf6314bbc
Question: What role should government play in making sure people can afford housing?
  1. Make government the main provider — build and operate public housing so everyone is guaranteed a home.
  2. Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.
  3. Build no public housing, but set binding rules on the private market like rent caps or required affordable units.
  4. Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets built.
  5. Rely on the market to set prices and supply — at most, cut the regulations and zoning limits that block private building.

#### Annex

# housing — served revision 598c879d-f387-461c-9120-fbbbf6314bbc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should government play in making sure people can afford housing?"

**Orientation:** standard. Rung 1 makes government the main provider of housing, rung 5 leaves prices
and supply to the market. Each rung states a **ceiling** on how far government goes ("build no public
housing, but …", "set no binding rules, but …"), so the rungs exclude each other.

**Levels with a lever:** federal, local, state. Federal action is funding
(public-housing capital, tax credits, vouchers); states set rent and zoning law and fund programmes;
local governments run housing authorities, zoning and inclusionary rules.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "public housing", "social housing", "mixed-income public housing", "housing
authority", "right to housing", "inclusionary zoning", "required affordable units", "rent cap",
"rent control", "rent stabilization", "Low-Income Housing Tax Credit" (LIHTC), "housing trust fund",
"density bonus", "by-right", "upzoning", "ADU" (accessory dwelling unit).

1. **"Make government the main provider — build and operate public housing so everyone is guaranteed a
   home."**
   - Means: government builds and runs housing as the main source of homes, and guarantees a home to
     everyone.
   - Operative clauses: [a] government is the main provider; [b] it builds and operates public
     housing; [c] everyone is guaranteed a home.
   - Establishing evidence looks like: own words or an instrument that makes public housing the
     primary supply and states a universal guarantee. A large public-housing programme that leaves
     private housing as the norm is rung 2, not rung 1.
   - Levels that hold a lever: federal; state. Local governments can build, but rarely at the scale
     of "main provider" _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both build public housing. Rung 1 needs [a] and [c]: the
     public sector is the main source and the home is guaranteed.
   - A **right to housing** met through **vouchers** or private units is not rung 1: [b] is
     public-built and public-run housing _(proposed)_.

2. **"Build a large public housing sector that competes with the private market to hold prices down,
   while private housing stays the norm."**
   - Means: government builds a large public-housing sector beside the private market, to hold prices
     down, but most housing stays private.
   - Operative clauses: [a] a large public-housing sector; [b] it competes with the private market to
     hold prices down; [c] private housing stays the norm.
   - Establishing evidence looks like: an instrument that funds publicly owned or social housing at
     scale as an alternative to market-rate housing, **plus** something that excludes rung 1 (the
     instrument or own words keep private housing as the norm). A public-housing appropriation alone
     → `direction-only` _(proposed)_.
   - Levels that hold a lever: federal; state; local (housing authorities, municipal developers).
   - Known chair-shaped instruments: the federal Homes Act (H.R. 9662, 2024), which funds social
     housing "as an alternative to market-rate housing", was used for the first Season 2 seat on this
     rung. Check that the row's evidence excludes rung 1.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 4 because a subsidy to a private developer for affordable units is
     not public housing. Public money for privately owned units is rung 4's subsidy clause.

3. **"Build no public housing, but set binding rules on the private market like rent caps or required
   affordable units."**
   - Means: government does not build housing, but it requires private owners and builders to keep
     some housing affordable.
   - Operative clauses: [a] no public housing; [b] binding rules on the private market (rent caps,
     required affordable units).
   - Establishing evidence looks like: a rent cap or inclusionary requirement **plus** evidence that
     the person does not support building public housing. [a] is an absence clause: a rent-cap vote is
     silent on public housing (V4.2 "Silence is not a clause") → `direction-only` alone.
   - Levels that hold a lever: state (rent law, statewide inclusionary rules); local (inclusionary
     ordinances, local rent rules where state law permits).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because many programmes pair a requirement with a subsidy (a
     density bonus in exchange for affordable units). A **required** set-aside is [b]; an
     **optional** bonus a builder may decline is a rung-4 incentive _(proposed)_.
   - "Like rent caps or required affordable units" lists examples of one clause; one example is
     enough for [b] _(proposed)_.

4. **"Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets
   built."**
   - Means: government pays or gives tax breaks to builders of affordable housing, and does not
     require owners or builders to do anything.
   - Operative clauses: [a] no binding rules on the private market; [b] subsidies or tax breaks;
     [c] aimed at building more affordable housing.
   - Establishing evidence looks like: a subsidy, housing trust fund or tax-credit measure for
     affordable construction **plus** evidence against binding rules (a No on a rent cap or an
     inclusionary mandate, or own words). A subsidy record alone does not exclude rungs 1–3 →
     `direction-only`.
   - Levels that hold a lever: federal (tax credits, grants); state (state credits, trust funds);
     local (local subsidies, fee waivers, land write-downs).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.
   - **Demand-side aid** (rental vouchers, down-payment help) is government money but does not get
     housing built → not [c]; `direction-only` _(proposed)_.

5. **"Rely on the market to set prices and supply — at most, cut the regulations and zoning limits
   that block private building."**
   - Means: the market sets prices and supply; the most government should do is remove rules that
     stop private building.
   - Operative clauses: [a] the market sets prices and supply; [b] at most, cut regulations and
     zoning limits.
   - Establishing evidence looks like: own words that reject public housing, binding rules **and**
     subsidies, or a record pattern that does. [b] is a ceiling ("at most"); a deregulation record
     shows the person cuts limits, not that they want nothing more.
   - Levels that hold a lever: state (statewide zoning and building-code law); local (zoning).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **deregulation law** reads like rung 5. A law that voids
     or cuts local zoning limits (by-right approval, density, lot size, added units) is `on-question`
     but `direction-only`: one such law cannot show the "at most" claim, and a person on rung 3 or 4
     can vote for it too _(codebook V2 "Refined 2026-09-26")_.

**Hard cases:**
- **Preemption (codebook V2, H12).** A state law that forbids local rent control or local
  inclusionary rules decides which level may act → `adjacent`. A state law that **removes** local
  zoning limits is the V2 refined case (rung 5 above).
- **Studies, task forces and housing-needs assessments** → V4 `study-directive`.
- **Homelessness spending** (shelters, supportive housing for people now homeless) belongs to the
  homelessness topics → `adjacent` _(proposed)_.
- **Tenant protections** with no rent rule (just-cause eviction, relocation aid) do not set a price
  rule or a required unit → `adjacent` _(proposed)_.
- **Budget and omnibus votes** with a housing item → V4 `multi-subject`.
- **Dense bills.** Housing bills often mix a zoning change with an affordability set-aside. Code the
  clause the person's act rests on, quote it as `provision_quote`, and check it against **every**
  clause of the rung.


## Sources

---
snapshot_id: f3c985bd-fcd3-5502-86a2-2a7503ac726a
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/bring-back-the-starter-home-in-california

Steve Hilton for Governor of California

---
snapshot_id: 53f1c8f7-5090-53bc-9723-584ca97e8dbf
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/stop-the-hidden-tax-on-new-homes

Saved from https://stevehiltonforgovernor.com/policies/stop-the-hidden-tax-on-new-homes (rendered page text, built-in browser, 2026-10-07) POLICY STOP THE HIDDEN TAX ON NEW HOMES: CAP GOVERNMENT FEES AND REGULATORY COSTS AT $50,000 ← POLICY ARCHIVE STOP THE HIDDEN TAX ON NEW HOMES: CAP GOVERNMENT FEES AND REGULATORY COSTS AT $50,000 A plan to save $150,000 on a typical new single-family home OVERVIEW For a long time, a young family in California could start out in life with a small single-family home and a yard. It might need work. It might not be in their first-choice neighborhood. But they could buy it, build a life and move up from there. Now that first step is out of reach for millions of people. California needs to build more homes, and it needs to build the kind of homes young families can actually buy. The National Association of Home Builders estimates that government regulation adds $131,734 to the price of an average new U.S. single-family home in 2026, or 26.4 percent of its price. That includes fees, building-code changes, delays, required studies, zoning restrictions and other government requirements. Here in California, the fee bill alone can exceed $100,000. A 2025 North State BIA study found that fees in the Sacramento region averaged $109,000 for a standard-sized single-family home, before counting the broader costs of code requirements and delays. The California Building Industry Association has also warned that state regulation imposes major costs and delays on homebuilding. Taking that heavier burden into account, Steve's plan uses a working estimate of around $200,000 in total government fees and regulatory costs for a typical new California single-family home. Steve Hilton will cap the combined cost of fees, permits and government mandates at $50,000 per new home, cut the rules and delays that make building so expensive, and open up more places for starter homes. The goal is to cut the estimated $200,000 government burden to $50,000, saving $150,000 on a typical new single-family home. California has room to build. Government needs to let it happen, and cut the cost of building. THE PROBLEM In the second quarter of 2026, only 19 percent of California households could afford a median-priced existing single-family home. A household needed an income of more than $228,000 to buy one. Think about what that means for a teacher, a police officer, a construction worker or a young couple starting a family. They work here. Their parents may live here. Their children should be able to grow up here. Yet buying even a modest home can seem impossible. Part of the problem is that we do not build enough. Another part is what we build. California has made it so difficult and expensive to produce a smaller single-family home that builders are pushed toward bigger, costlier houses. The family looking for its first home is left with fewer choices. HOW WE GOT HERE Before a shovel goes into the ground, a builder can face fees from multiple agencies, costly requirements and an approval process that drags on for years. Eventually those costs reach the buyer. A UC Berkeley study of seven California cities found that development fees alone came to between 6 and 18 percent of the median price of a new home. The study also found that builders often struggled to get a reliable estimate of what they would owe. How is anyone supposed to plan and build an affordable home when the government cannot give them a clear price? Then there is the question of where homes are allowed to go. Sacramento has spent years trying to fit new housing inside existing developed areas while making it harder to create new neighborhoods. We should build within our cities. We should also be able to build the small, single family homes with yards that young families want. STEVE'S PLAN CAP FEES, PERMITS AND GOVERNMENT MANDATES AT $50,000 PER NEW HOME Steve will propose a statewide cap on the combined costs that state and local government add to a new single-family home through development fees, permits and mandatory requirements. The cap will cover both charges paid to agencies and the cost of complying with requirements imposed as a condition of approval. Builders should be able to see the full government cost before committing to a project. Agencies should not be able to evade the cap by renaming a fee or replacing it with a costly mandate. This will require changes in how infrastructure is paid for. Roads, water and other services have real costs. Those costs should be planned for openly, with any charges to future homeowners disclosed before they buy. A lower upfront bill must mean a real reduction in the buyer's overall costs, rather than the same charges appearing later under a different name. The answer cannot be to keep loading an unpredictable bill onto every new home and then wonder why young families cannot afford one. MAKE THE STARTER HOME POSSIBLE AGAIN Steve wants builders to be able to offer smaller single-family homes, including homes around 1,000 square feet, on lots that make sense for a first-time buyer. California should stop piling requirements onto a modest home that make it cost nearly as much to develop as a much larger one. State building rules should be examined for their effect on housing costs while maintaining essential fire, earthquake and construction safety. GIVE BUILDERS AN ANSWER A home that meets the rules should not spend years waiting for permission. Steve will set firm deadlines for decisions on housing applications and end the cycle of repeated hearings and changing demands. Once a project is approved, government should not impose a new set of requirements halfway through. Steve has also proposed changing CEQA so that housing projects cannot be held up by private lawsuits filed under the law. Environmental rules would still apply, with enforcement by district attorneys or the attorney general. That was a central part of the California Homeownership Affordability Act, the ballot initiative Steve proposed in 2023. OPEN UP MORE PLACES TO BUILD California needs homes in existing neighborhoods and new communities. Steve will remove state barriers that prevent communities from planning new neighborhoods where there is a workable plan for water, roads and other services. Families should have the choice of a smaller home with a yard. State government should stop treating that choice as something to be stamped out. A BETTER WAY FORWARD The first home does not need to be a mansion. For many families, a small, single family home and a little yard would change everything. California used to build those homes. We can build them again. ← Back to all policies

---
snapshot_id: d864e5c4-dcf3-5f19-9c75-8b0e0a1bb258
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/b793ce44-9344-4309-ad4d-5887f9d044da

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## Housing Affordability (CBS LA) - CA Governor Candidates - OTR page: https://ontherecord.empowered.vote/meetings/b793ce44-9344-4309-ad4d-5887f9d044da - Video: https://www.youtube.com/watch?v=eQZiD8dv7dI - Date on On the Record: 2026-04-12 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [0:08] do you do for those folks? >> Get rid of the regulations, the mainly environmental regulations that are making it more much more expensive to build housing. So the basic cost of building is four or five times as high in California. Number two, we have to end the lawsuits that are making it more expensive to build housing here cuz they make the whole process much longer and drawn out and you have to go to court and fight these lawsuits. That's because of something called CEQA, the California Environmental Quality Act. That's become pretty well known, but what's not known is it's not so much the regulations in CEQA itself, it's the lawsuits from CEQA because CEQA uniquely has something attached to call the private right of action. All right, so that means that anyone can file a lawsuit. 70% of CEQA lawsuits are used to block housing. Most of those lawsuits are filed nothing to do with the environment. That's the pretext. They're filed by the unions, labor unions to extract what they call project labor agreements, which require one or two or often both of these conditions, prevailing wage and what they call skilled and trained labor. Skilled and trained is a union monopoly. Prevailing wage is about two or three times higher than the market rate. That increases the cost of housing. So we've got to deal with that. The other point and and this is the one where I think no one's really focused on this. Even those two big bills that Gavin Newsom just touted as solving the housing crisis. We're going to abolish CEQA for new housing and all this kind of stuff. It only affected what they call infill development. So the housing that is within the current built environment in California. Why? Going back to what I said earlier, it's an ideology. There's this ideology of what they call density that we can't have sprawl They call it sprawl, right? Where you build outwards, the suburbs that California was famous for. They call it sprawl, I call it the California dream. A single family home where you can raise your family with a yard and enjoy the weather. They're against all of that. They say you can only build in the existing urban footprint. What does that mean? The price of land goes up cuz you're restricting the area that you can build in. And so I would get rid of all of that. That is the result of regulation. They call it VMT, vehicle miles traveled. They put these calculations in and they say, "Well, if you build over there, you're going to have more car journeys, vehicle miles traveled, so we're not going to allow you to do that." So we've got to relax that. And they say you've got to have density. We already have the highest density in the country. Barely 5% of our land in California is developed at all. There is plenty of room to build outwards and let people have that California dream of a home of their own. That's

---
snapshot_id: f1c1fdd0-998c-53f5-989d-5f48cd6b1cf6
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california

Saved from https://stevehiltonforgovernor.com/policies/ten-new-cities-for-california (rendered page text, built-in browser, 2026-10-07) POLICY TEN NEW CITIES FOR CALIFORNIA ← POLICY ARCHIVE TEN NEW CITIES FOR CALIFORNIA STEVE HILTON’S NEW CALIFORNIA DREAM CHALLENGE California used to build the future. We built the State Water Project, world-class universities, ports, highways and entire communities where working families could buy their own home and build a life. We offered people opportunity better than anywhere else in the world. It became known as the California Dream. But after sixteen years of one-party rule, that Dream has all but died. People are moving out of California in their millions, rather than moving here as they once did. Young people cannot see their future here. Instead of building the future, we are exporting it to other states. Today California makes it almost impossible to build anything. Young people work hard and save what they can, but homeownership keeps moving further out of reach. Employers cannot find workers who can afford to live nearby. Families are giving up and leaving. The usual housing debate is a dead end. The state imposes mandates. Counties and cities resist them. Developers spend years fighting through approvals and lawsuits. When something finally gets built, it is often housing on its own, with the roads, water, schools, jobs and parks left for someone else to deal with later. Steve Hilton will take a completely different approach. We have plenty of space to build in California. The proportion of our land that is developed in any way at all is around 6%, making us already one of the more densely developed states in America. We could increase that to 7% and we’d be ranked no lower for density, but with space for 10 million households in new single family homes on quarter acre lots. So let’s build again! The New California Dream Challenge will invite counties to compete for a small number of New California Dream Charters. Counties can also join with willing cities to submit a bid together. They will choose the site, assemble the land and bring employers, builders, schools, utilities and other partners to the table. The state will not draw circles on a map and force new towns on communities that do not want them. Counties will decide whether to take part. The state’s job is to offer a prize valuable enough that ambitious counties and cities will want to compete. The aspiration is ten beautiful, vibrant new communities that will be wonders of the world, with attainable homes, good jobs, schools, health care, amazing architecture, parks and public spaces. Each will be built around a major university, trade school, research center or comparable anchor institution. Modern water, energy, construction and transportation systems will be designed into the community from the beginning. Four or five communities will be selected in the first round. The program will expand to ten once the model has been proven, and lessons learned. CHANGE THE DEAL FOR COUNTIES Counties do not reject large new communities because they lack ambition. They reject them because the current deal is bad. New homes create immediate demands for roads, sheriff’s deputies, firefighters, schools and other services. Under Proposition 13, the local revenue needed to pay for those services can take years to catch up. Existing residents see construction and congestion long before they see any benefit. At the same time, CEQA litigation, local growth-control rules and annexation fights can leave a major project trapped for years. A county can spend political capital approving a new community and still have no certainty that it will ever be built. Just yelling at counties and cities to approve more housing - the imperious, centralizing approach of the current administration in California - does not change any of that. We need a new approach. A less top-down, more human way to build the housing we need. The state has to change the deal. The New California Dream Challenge will concentrate major state support on a small number of winning proposals. Winners will receive enough regulatory certainty, infrastructure support and fiscal protection to make saying yes a rational and attractive choice. In return, local commitments will be binding - so everyone knows that unlike what we’ve seen for years now, these are housing promises that will actually be kept. FIND LAND THAT CAN SUPPORT A WHOLE COMMUNITY California does not currently know how much government-owned land could realistically support a new community. The Department of General Services’ current Statewide Property Inventory reports nearly 7 million fee-owned acres. That figure excludes Caltrans operated highway rights-of-way and airspace. Many of those acres serve an important public purpose. They include parks, wildlife areas, sovereign lands, universities, prisons and other functioning government facilities. But there is clearly land in public ownership that is vacant, underused or no longer needed. When DGS screened state holdings for housing in 2019, it reviewed more than 44,000 parcels. It initially identified 690 properties, comprising approximately 1,200 parcels, as potentially viable. It ultimately selected 92 properties in 28 counties for affordable housing. The California State Auditor found that those 92 properties could support more than 32,000 homes. The latest state inventory lists 3,295 state-owned properties covering nearly 7 million acres. Some of that land is protected or already in use. But much of it is vacant, underused or no longer needed, and state government cannot say with any confidence how much land falls into those categories. In his first 100 days, Steve will order a comprehensive New California Dream Land Review, building on the existing DGS and Housing and Community Development inventories, including a parcel-by-parcel audit. State records will be checked against county assessor data, and the results will be published in a searchable public map. Agencies will have to show that the property they control is being used or is needed on an actual timetable. The review will identify areas with enough contiguous or realistically assembled land to support an entire community. Each candidate area will be evaluated for: Total and contiguous acreage, ownership and current use. The feasibility and cost of assembling the site. Terrain, grading and construction conditions. Water supply, storage, recycling and groundwater conditions. Access to roads, rail, power and other regional infrastructure. Fire, flood, fault and liquefaction risks. Habitat, conservation, tribal, cultural and farmland constraints. Contamination and remediation costs. The likely cost of the infrastructure needed to make the site work. Legal restrictions or continuing public uses that would prevent development. The existing process has largely asked whether apartments can be built on an individual government parcel. The New California Dream Land Review will ask a different question: can a complete community, including the single family homes that most Californians want (and the starter homes young families need), be built in this area? The results will be published in a searchable public map, giving counties information to help evaluate whether and how to bid. New California Dream proposals may include such state property, county or city property, voluntary private transactions or a combination. The Challenge will not use eminent domain to assemble a development site from unwilling private owners. State land is one asset available to bidders, but it is not the premise of the program. If a winning proposal includes state property that is genuinely excess and suitable for development, the state may sell it, provide it through a long-term ground lease, exchange it for other property or contribute it to the development authority. The method will be chosen based on what produces the best public return and keeps the project financially viable. Where legally available, proceeds from the sale or lease of excess state property will be reinvested in infrastructure for the New California Dream Challenge. Those proceeds will supplement the program. The plan will not depend on speculative land sales to pay for its core commitments. WHAT A WINNING COUNTY RECEIVES A New California Dream Charter will provide a coordinated package of regulatory, financial and institutional support. FAST AND CERTAIN APPROVALS Each winning master plan will be designated as an Environmental Leadership Development Project or receive equivalent statutory treatment. There will be one fast-track coordinated environmental review of the full master plan. Later phases that remain inside the approved area will receive ministerial approval instead of beginning the process again from scratch. Legal challenges will follow an expedited process to resolve litigation within 270 days. One lawsuit should not be allowed to hold an entire community hostage for years. Each project will have one accountable state-local approval team, a single public schedule and firm deadlines for agency decisions. The county chooses whether to compete. Once it wins, approves the charter and accepts the state package, it cannot revive an urban-limit line, orderly-growth ordinance or similar local restriction to kill the project later. The state preemption applies only to the winning sites and only after the county has voluntarily joined the program. INFRASTRUCTURE AND FISCAL PROTECTION Winning counties will receive front-loaded state support for the first major roads, water and wastewater systems, schools, parks and civic spaces. Counties will not be asked to finance the entire opening phase on their own. The state will also provide a temporary, declining backfill for the documented gap between early local revenue and the actual cost of public safety and other county services. That support will end as the new tax base grows. Winners will receive streamlined authority to use Enhanced Infrastructure Financing Districts, community facilities districts and other value-capture tools so later phases can increasingly pay for themselves. The state package will be financed through a dedicated infrastructure appropriation, existing state and federal infrastructure programs, project financing and the future value created by the community. Land revenue, where legally available, will be an additional source rather than the foundation of the plan. State support will be released in stages. Permits issued, homes completed, infrastructure operating, jobs occupied and parks opened will unlock later funding. WATER AND AN ANCHOR INSTITUTION There will be no charter without a verifiable long-term water supply. The state will help winning counties ensure any storage, recycling, groundwater banking, conveyance and conservation projects needed to secure that supply. But a political promise that water will somehow appear later will not qualify. Every community must also be built around a serious anchor institution. That could be a specialized University of California or California State University campus, a major community-college and trade-school complex, a research institution or something comparable. The institution must commit to its planned scale, funding and opening date before the charter is awarded. Where the anchor is a public institution, the state package will include the necessary legislative, budgetary and institutional commitments. LOCAL CONTROL AND FUTURE SELF-GOVERNMENT The charter will establish how the community will be governed during construction and after it has grown. An interim development authority may coordinate infrastructure, land disposition and approvals. Each charter will include a path to incorporation as a new city or annexation to a willing existing city once population and fiscal thresholds are met. WHAT COUNTIES MUST PUT ON THE TABLE A county should not win because its consultants produced the prettiest presentation. The scoring rules will be published before bids are submitted. Before a proposal can even be scored, it must pass several basic tests. The county board of supervisors must formally approve the bid. Any county-city consortium must have formal approval from participating local government. The bid must show control of enough land for the entire proposed community or a credible plan to assemble it. That means an ownership map, executed options or participation agreements from major landowners, identification of any state property being requested and a schedule for completing the assembly. The land requirement will be based on the proposed population, housing and employment plan, not an arbitrary statewide acreage number. A bidder must show enough room for homes, jobs, the anchor institution, schools, infrastructure, parks and future phases. The bid must also include a secure water plan and a 30-year fiscal-impact statement showing that the community can support county services after the temporary state backfill ends. Finally, it must include a community-benefits fund tied to population and construction milestones. The fund can support road improvements, public safety, schools, parks in nearby communities, local hiring, down-payment assistance or protection from sudden local tax increases. Existing residents should see a benefit before they see years of construction traffic. Proposals that pass those tests will be scored on five criteria. 1. HOMES PEOPLE CAN AFFORD Counties will need to state how many homes will be built, what kind and when. The communities should include starter homes, family homes, apartments and housing for a range of incomes and stages of life. A substantial proportion of the homes offered for sale should be single family starter homes for young families, priced within reach of first-time buyers. Housing phases must be tied to infrastructure, jobs and the anchor institution. The first neighborhoods must have roads, utilities, schools, shops and usable public spaces before later greenfield phases are released. 2. JOBS, NOT JUST BEDROOMS A new town or city cannot become a distant bedroom community with a brutal commute. Employers should therefore be part of any bid, with specific plans to bring new investment and jobs. Retail and local services are of course a vital component of any new community, but they will not satisfy the employment requirement on their own. Moving an existing job from one California city to another will not count as job creation. 3. A COMMITTED ANCHOR INSTITUTION The university, trade school, research center or other anchor must provide a binding commitment stating its planned size, funding, opening date and role in the community. The strongest bids will place private laboratories, apprenticeships, business incubators and employer training alongside the institution. The anchor is the economic and civic heart of the community. It is not an amenity to be added if the budget permits. 4. ARCHITECTURAL QUALITY California should build as if beauty matters - which it does. We are the most beautiful state in the nation and our built environment should reflect that. Each bid must therefore include an enforceable design or form-based code covering streets, building types, materials, ground-floor uses, public spaces and civic buildings. An independent design-review body will have the power to reject generic development that fails the code. The test is simple: does this look and feel like a place where people will want to build a life? 5. PARKS AND PUBLIC SPACES Parks, plazas, greenways, playing fields and schoolyards must be part of the first neighborhoods. They cannot be whatever scraps of land remain after the profitable building is finished. Each bid must identify the land, construction schedule, public-access protections and permanent maintenance funding for its parks and public spaces. Later housing phases will not be released if the promised early public spaces have not been delivered. THE CHARTER IS A CONTRACT A New California Dream Charter will not be a vision document. The master plan, housing schedule, design code, parks map, infrastructure plan, fiscal commitments and anchor institution timetable will be enforceable exhibits to the charter. Housing phases, infrastructure draws and additional land releases will be tied to delivery. If the first housing increment is not completed, the next tranche stops. If the first parks are not open, the next phase stops. If the anchor institution misses its commitment, state support stops. Unused state money will be clawed back. Commitments made to nearby communities will be enforceable. Design standards and public-space requirements will survive changes in developers and county leadership. If the original private partner fails, the development authority can rebid the remaining land and work. One bankrupt builder will not be allowed to kill the entire community. Progress, spending and milestone decisions will be published. Californians will be able to compare what was promised with what was actually built. WHY COUNTIES WILL COMPETE The Challenge turns the main reasons counties say no into reasons to bid. The infrastructure package and temporary fiscal backfill change the early financial calculation. The anchor institution, employers, students and new investment create the long-term tax base that county supervisors can defend at a budget hearing. Politically, a county will not simply be approving another subdivision. It will be competing to win a university or trade school, new infrastructure, protected parks, good architecture and thousands of attainable homes. Legally, the approval certainty applies only to the winning site and only in return for enforceable public benefits. The veto points are removed because the county has chosen the plan and signed the contract. For inland and rural counties, the Challenge offers a path to an institution and level of investment they might otherwise never receive. Smaller cities can join a county bid and gain new residents, employers and a stronger future tax base. Counties will compete because the prize is worth winning. START WITH FOUR OR FIVE, THEN BUILD TO TEN The first round will award four or five New California Dream Charters. The scoring system will be published before bids are due. An independent panel will evaluate the proposals, and the scores and reasons for selection will be made public. The strongest bids will have a willing local government, control of a suitable site, a credible water and infrastructure plan, regional transportation access, committed employers and an anchor institution ready to go. The program will expand towards ten only when the first winners have something real to show: occupied homes, working infrastructure, open parks, jobs on site and an anchor institution under construction or operating. After ten years, an independent evaluation will measure homes built, jobs created, infrastructure costs, water performance, public spaces, architectural quality and the county’s fiscal position against the original bid. If the model works, California will have ten new communities and a proven way to build more in the future. If it does not work, the state will change it or stop it. California has the builders, workers, technology and talent. What has been missing is a government willing to clear the way and counties with a reason to say yes. Counties will choose. The best proposals will win. A NEW DECADE OF BUILDING The New California Dream Challenge is part of Steve’s vision for a New Decade of Building, laid out in a recent speech to the Commonwealth Club in San Francisco. California no longer knows how to build. Housing, energy, transportation and water projects spend years trapped in overlapping reviews, bureaucratic delays and lawsuits. Steve will ask the Legislature to approve a New Decade of Building. For ten years, California will suspend the state rules, approval processes and litigation provisions that make building anything so costly and time-consuming. Agencies will review permits at the same time instead of passing a project from one office to the next. They will have firm deadlines to make decisions. CEQA will be returned to its environmental purpose instead of being used to block projects for reasons that have nothing to do with the environment. Growth and innovation require abundant housing, reliable energy, modern transportation and enough water. These things must be built, before it is too late. California built the future before. It is time to build again. ← Back to all policies

---
snapshot_id: 38868427-b9b7-51a5-9769-d536e19d7919
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/77f91eb0-90c0-47d7-8c37-cda599ea643b

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (NBCLA and Telemundo) - OTR page: https://ontherecord.empowered.vote/meetings/77f91eb0-90c0-47d7-8c37-cda599ea643b - Video: https://www.youtube.com/watch?v=UUOsiG5tkDU - Date on On the Record: 2026-05-07 - Kind: debate · Governor Debate (NBCLA and Telemundo) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [2:32] Yes, the California dream was built on that idea of owning your own home. And right now we have the highest housing costs in the country and the lowest home ownership. Young people saying to me all the time, I can't imagine making my life in California because I'll never be able to own my own home. We've got to change direction on housing. Yes, we've got to simplify the regulations that make it so expensive, two or three times more expensive to build housing compared to other states. Yes, we have to stop the hidden taxes on house building. But the big change we need to make, which the Democrats on this stage aren't prepared to make, is to end this ideology which says the only acceptable form of housing is to shove apartment buildings into suburban neighborhoods. We've stopped building the kind of starter homes and single family homes we used to build so well in California that made the California dream a reality. And that is what I will get back to as governor to restore that California dream of home ownership. [9:16] He's trying to remember his lines. [12:31] Exactly. [15:19] So just a couple of observations on what we heard in the previous answers. I love all the stories of the California dream for some of my friends and colleagues on this stage, but the California dream they're talking about happened when you had a Republican governor in California. And that's what we need to get back to to restore it. Matt Mahan talked about housing. His city was just rated the least affordable for housing in the world. So what that all points to is that actually if we want change in California on all these issues, we can't keep doing the same thing over and over again, specifically on insurance. The things we haven't heard that I would do as governor is number one, enforce the actual regulation in the original proposition 103 that set up our insurance commission and the regulations around it, which says that rate changes need to be approved in 60 days. Now it takes over a year. That's one of the reasons that they're leaving. And the other massive one, lawsuits. Lawsuits are adding sometimes up to $15 ,000 a year on to run to insurance premiums. And these Democrats won't change it because they are funded by the trial lawyers. [20:21] We are going [21:24] No. [21:25] Stop spending tax -based money on pointless things and improve our roads, which are the worst in the country because of [21:32] policies. [21:50] either yes or no. The bill's [24:49] So Matt mentioned restaurants. I actually did open a couple of restaurants, but not here, back in the day in England, before we moved here with my wife and my family in 2012. And unbelievably, it's actually much harder to do it here in California, which should be the home of enterprise and opportunity, the best place in the world to do business. And the fact is, when we talk about all those issues, there's this famous saying that comes to mind. The definition of insanity is doing the same thing over and over again and expecting a different result. Well, here in California, we've been voting Democrat over and over and over and over again. And look at the results. The highest unemployment rate in the country, the highest poverty rates, the worst climate for business. We cannot expect to make changes for the better if we keep voting Democrat. I will exclude Antonio. I agree with you, Antonio. You definitely have a more pragmatic approach to this, and that's what we need from our next governor. Thank you, Mr. Hilton. A problem -solving, pragmatic, common sense approach. [26:05] 50th out of 50 states by Chief Executive Magazine. And the person on [30:39] of Democrat one -party rule, why do you think that [31:57] No. [32:04] Are you happy with that, Tom? How do you want to be charged by Matt? [39:38] I was just trying to offer a fact check. Homelessness actually has gone up in San Jose. It's actually [39:55] you noted, he didn't challenge the fact that homelessness has gone up on his watch. Now, [40:02] the good news in this debate is that actually there's a lot of agreement among many of the candidates about the nature of the problem and how we solve it. But we've got to think about the fact that who's been in charge [40:15] all these years? Some of these Democrats on the stage, they talk as if we're in some parallel universe where Democrats haven't been running this state for the last 16 years of one -party rule. You look at Javier. 36 years he's been a career politician for Democrats. It's just got to change. We need change if we're going to make progress. And that is what Chad's plan is exactly right. And I just add one thing to it, which is we need to enforce the law when it comes to homelessness. Just as Spencer Pratt laid out in the mayor's debate to you earlier, it's illegal to live and camp on the streets. And that's the starting point. A [42:10] I haven't done. [42:15] ask [42:17] I didn't. [43:34] Thank you very much. I tell you what I haven't done, Javier, is break state and federal law by taking money from a campaign account and funneling it to a senior aid, breaking those laws and then denying it. I tell you what I haven't done, which we reveal today, which is to take a taxpayer -funded organization from your money, your taxes, are paying illegal immigrants to campaign for Javier Becerra through an organization called CHERLA. And he's accepted their endorsement. It is completely outrageous. [52:43] Thank you very much. Unlike everybody else here, I actually am an immigrant. I'm a proud American, American citizen. And I am the candidate of the legal immigrant community for the legal immigrant community so that they can have the California dream. Just as my parents had it when they moved from Hungary, fleeing communism to build a new life in England. That's what California is all about. But it's got to be managed and orderly and legal. And that's what we have to be honest about in this whole discussion about immigration and its enforcement. I can tell you very clearly that when I'm governor, as I've said, I will be there for our immigrant communities, our legal immigrant communities, but also we'll make sure that all our laws, all our laws, are peacefully enforced. We can't just stand up here and decide which laws we like and which laws we don't. If we don't like the laws, we've got to change them. But the governor's job is to enforce them. And as governor, I will do that peacefully and calmly and cooperatively with the federal immigration authority. [53:57] I understand exactly what it's like to be in a country without those privileges because that's my life and my story when my parents fed communism in Hungary and I grew up in a household with a single mother, working -class immigrant story, just like so many millions in California. My stepdad worked construction. My first job, project manager for a construction company. So, yes, I absolutely understand that. And that opportunity is what I want for every single one of you. Thank you, sir. Every single one. [55:28] Yeah [55:32] It's a weird question, to be honest. I agree with Katie. [55:40] I think you might even [56:03] it open. [56:10] Extend [56:13] Yes, extend it and build new ones. [56:17] Completely nuclear. [56:30] Yes. [56:31] Yes. [56:33] Yes. Yes, I published my plan on this last week. I would exceed other countries. We got to be the best in the world.

---
snapshot_id: 8bb8d4fd-751e-5ef0-ad1c-64f892ae0dc5
source_kind: news (excerpt only)
url: https://calmatters.org/california-voter-guide-2026/governor

… Controller Treasurer Superintendent of Public Instruction Board of Equalization Insurance Commissioner Supreme Court U.S. House State Senate State Assembly Prop 1 Housing bond Prop 2 Rainy day fund Prop 3 High-income tax Prop 4 Public fundraising Prop 5 Recall reform Prop 37 Homebuyers loan Prop 38 Research bond Prop 39 Voter ID Prop 40 Billionaire tax Prop 41 Tax audits Prop 42 Property taxes Prop 43 Tax threshold Prop 44 Clinic funding Prop 45 Environmental review Quizzes es Leer en español Governor of California The California governor is the most powerful elected official in the nation’s most populous state, commanding a $300 billion budget. The governor shapes policy for 39 million residents, signs or vetoes legislation, appoints judges and members of regulatory agencies and leads crisis response from wildfires to pandemics. California’s governor wields outsized national influence, making the office a launching pad for presidential ambitions. Xavier Becerra D Steve Hilton R Candidates Xavier Becerra D Democratic Former U.S. Health secretary, former state attorney general Becerra represented Los Angeles in Congress for more than two decades before being appointed California’s attorney general in 2017. He led the state’s numerous lawsuits against the first Trump administration and Republican states. He was U.S. secretary of Health and Human Services under President Joe Biden, steering the administration through the COVID-19 vaccine rollout and receiving criticism for the agency’s lack of care of migrant children in its custody. Becerra says he’s open to revising California’s climate goals to keep fuel affordable and wants to declare a state of emergency to freeze utility and insurance rates. Steve Hilton R Republican Former adviser to UK prime minister, former Fox News host Hilton, who is British American, was senior adviser for former conservative U.K. Prime Minister David Cameron from 2010 to 2012 before moving to California, where he …

---
snapshot_id: 893202a1-ed86-5d86-8db2-81d2ba7f39b7
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/bring-back-the-starter-home-in-california

Saved from https://stevehiltonforgovernor.com/policies/bring-back-the-starter-home-in-california (rendered page text, built-in browser, 2026-10-07) POLICY BRING BACK THE STARTER HOME IN CALIFORNIA ← POLICY ARCHIVE BRING BACK THE STARTER HOME IN CALIFORNIA A Califordable Plan for First-Time Buyers THE PROBLEM California used to be a place where you could get ahead. Work hard, save up, buy your first home, and build a life. That path is disappearing. A generation ago, buying your first home was something many Californians could imagine doing in their 20s. Today, the median first-time homebuyer is 40. Today, first-time buyers are being shut out of the market entirely. The homes that do get built are too big, too expensive, and completely out of reach for young, middle-class families. Starter homes, the foundation of a healthy housing market, have almost vanished. That’s not just a housing issue. It’s an opportunity issue. When there’s no entry point into the market, families can’t get started. Workers can’t afford to stay. And the entire system locks up, with fewer homes available and higher prices across the board. More than half of Californians under 35 say housing costs make them consider leaving the state. California isn’t building the kinds of homes people actually need. And until that changes, affordability will keep getting worse. WHY THIS IS HAPPENING This is the result of years of bad policy under one-party rule. California Democrats have made it harder and more expensive to build at every step of the process. Costs have been layered on without regard for what they do to the final price of a home. Fees, mandates, and requirements are often the same regardless of size, which makes smaller, entry-level homes far less viable to build. When the cost structure looks like that, builders don’t stop building—they shift toward larger, more expensive homes where the numbers still work. At the same time, the approval process has become slower, more complex, and more uncertain. Projects face overlapping requirements and drawn-out timelines that add months or even years before construction begins. Every delay adds cost, and those costs are passed directly on to buyers. California stopped building 1,000-square-foot starter homes and started building 2,000-plus-square-foot houses few young families can afford. When risk is high and costs are unpredictable, builders shift toward projects that can absorb those costs. Starter homes get squeezed out. None of this is accidental. It’s the predictable outcome of years of policy decisions that ignored cost, supply, and basic economics. THE PLAN 1. MAKE STARTER HOMES PROFITABLE TO BUILD If we want more starter homes, we have to make them financially viable. Reduce or defer fees for entry-level homes Align fees with home size instead of flat charges Allow fees to be financed over time instead of paid upfront Eliminate state income tax on profits tied to qualifying starter home construction Builders should not be punished for building the homes young Californians actually want. 2. FAST-TRACK STARTER HOME PROJECTS Time kills starter home development. Create a fast-track approval process for projects that include starter homes Set clear, enforceable timelines for approvals Encourage innovative design that builds in flexibility, for example starter homes that can easily add more space to accommodate family expansion If a project meets the rules, it should move quickly. No more endless waiting. 3. ENFORCE ACCOUNTABILITY One of the biggest barriers to starter homes is the lack of follow-through. Establish a Governor’s Housing Expediter to unblock stalled approvals Require adoption of proven best practices for housing development Impose real consequences when projects are delayed or blocked without justification If we’re serious about building more homes, we need to make sure it actually happens. 4. STOP ADDING COSTS We cannot keep raising costs and expect prices to fall. Implement a five-year freeze on new housing regulations Require cost-benefit review of recent mandates Prevent new layers of requirements that drive up construction costs Before adding more rules, we need to understand what the current ones are doing. 5. EXPAND STARTER HOMES IN EXISTING NEIGHBORHOODS Starter homes don’t only come from new subdivisions. Expand incentives for building and selling ADUs as entry-level homes Create financing tools to lower upfront costs for buyers Encourage smaller, more affordable units within existing communities This creates new opportunities without starting from scratch. 6. CREATE A STARTER HOME LOAN PROGRAM Young Californians should not need family wealth to buy their first home. Create a state-backed Starter Home Loan Program for first-time buyers purchasing qualifying starter homes Allow assistance for down payments, closing costs, or interest-rate buydowns Structure the program as a deferred second loan, repaid upon sale or refinance Tie the program directly to newly built starter homes to increase supply, not just demand California should make it easier to buy your first home, not just easier to qualify for debt. CONCLUSION The starter home was the foundation of the California Dream. Today, it’s out of reach. If the next generation can’t buy their first home, they won’t stay. And if they don’t stay, California doesn’t work. We don’t need more excuses or more bureaucracy. We need to build again—starter homes, at scale, at prices young families can actually afford. That’s how you open the door again. That’s how you make our state Califordable again. ← Back to all policies

---
snapshot_id: 5b0cc4d7-2502-5e64-9da9-ff72e242c232
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [7:19] the change we need is away from the policies that have brought us to the situation that all the people on this stage described there's a difference though only two of us here actually represent real change away from that like millions of people before me I came to this state in search of a dream like my parents who left communist Hungary to England in search of freedom I was brought up in a working -class immigrant family I made it to Oxford University started a business worked in 10 Downing Street came here in 2012 my wife and my two sons taught at Stanford started a business and now leading the race for governor I want every single one of you to know that I see you I believe in you I won't accept that the California dream is something we talk about in the past tense wherever you want to go I want to clear the barriers away more money in your pocket your first hundred grand tax -free enough with the bureaucracy and the nonsense we will restore the California dream [15:51] I love the way Matt talks about how he's gonna lower costs when his city was recently rated the most expensive the least affordable for housing in the world [16:06] he's not fixing it because he's not fixing it because we're building housing are as high this year as they ever were all the plans he talks about have not actually reduced the cost of housing because fundamentally he supports the policies that have made housing and gas the most expensive in the country we need a change from those policies not more of the same I [22:13] well I don't think it's fair that California taxpayers who can barely afford their own health coverage should be paying for the health care of citizens of other countries and if you look at the record of Javier it's exactly what was just saying that you cannot believe that any change will come from these people he as health secretary dismantled the unit and HHS that was supposed to crack down on fraud billions of dollars of fraud as a result of his rule as HHS secretary and there's another point I think we have to acknowledge we learned today that Javier implicated in this corruption scandal today we learned that he knew about illegal and improper payments from his campaign account to his former chief of staff honestly it pains me to say because I like you personally Javier but you shouldn't be on thanks a lot you shouldn't be in this race you should be preparing your criminal defense [24:32] it Javier [24:34] talk about your chief of staff who said that you knew about these payments let's talk about [27:23] in the polls I think I get [34:30] no instead of forcing housing into places that don't want it we need to build housing in the places that do want it and I'm afraid all this conversation around housing we're not thinking big enough it's all just fiddling around the edges it's a crisis here in California so many young people I see they've given up on the idea that they could ever own their own home we need to build outwards not just upwards with apartment building shoved into suburban neighbors you know that only 6 % of our land is developed in California we could increase that to 7 % and there would be room for 10 million households and single -family homes so that young families could see their kids play outside in California we need to think big again back to the days when we used to build amazing things in California the suburbs of Southern California the state water project we should be thinking about how we store the ambition the abundance of California [41:20] believe a word he's saying his party increased those regulations mr. [47:06] yeah and we need to have common sense on climate change not ideology that ends up being counterproductive and exactly as Chad said hurting every small business and family and everyone in California I'm an environmentalist we love our beautiful natural landscapes our climate here in California we've got to protect that clean air clean water of course that's right but look at some of the things that we're doing in the name of climate change the wildfires that occurred in the Sierras in 2020 because the forests weren't managed properly the co2 emissions from that one year of mega wildfires wiped out all the savings from climate policy in the previous 20 years look at what's going on with our gas prices the highest in the country because instead of getting oil and gas from our own oil production here in California we are shipping it 7 ,500 miles in giant super tankers spewing out carbon emissions in the name of climate we are increasing carbon emissions we need some common sense here [48:55] a [49:54] look I don't know if you know how many EVs are on the roads in California the proportion the idea that that's gonna actually half of the [50:10] number man statewide yeah [50:13] do you know [50:14] it's another percentage of our vehicles on the roads [50:19] 7 % and he wants and it's power our power grid with that it's a lot of batteries this is what you get tell me the math on the batteries thank you you get from ideologues who are not actually it's actually called innovation [50:33] very much how we fix things how to make things work [58:01] Yes. We have to lower gas prices. [58:15] No. [69:28] We need to make it easier for working -class Californians to get into the UC system. As we used to, the costs are so high, the structure of the courses, all of this needs to change. I don't believe in artificial caps and regulation. That's the kind of policy that has got us into this mess. And I have to say, listening to my Democrat friends here, talking about education, it's as if they haven't been in charge for the last 16 years. They are the policies that they support that have got us to a position where less than half the kids in our schools can read at grade level. For math it's 35%. We need new management in this state if we're going to turn things around. We can't have more of the same. We need to make sure we use phonics to teach kids to read. Make sure that they can read by third grade. And like Mississippi does, not go to fourth grade if that doesn't happen. We need to hold teachers accountable also to make sure that we reform the pensions because right now 10 and a quarter percent of every teacher's salary is going towards their pension. We need that to change as well. [73:37] This is not about abortion rights. This is about one state trying to undermine another state's laws. We have a federal system. Yes or no, Mr. Hilton? Sorry? [73:47] Yes, I would follow the law, and that's because we have a constitution in this country that we need to [73:56] abortion rights. Mr. Steyer? It is about abortion. No, it isn't. [73:59] Undermine democracy in another state. Thank you, Mr. Hilton. The people in that state chose differently to California. [74:07] interfere in another state's laws in that way? Mr. [74:12] don't want Louisiana dictating our laws. We shouldn't be dictating Louisiana. Maybe you ought to run for governor. Mr. [74:22] Hell no. [74:56] I'm afraid it's not as simple as that. It really isn't. No, I'm serious. This is exactly the reason we get in. This [75:04] it's not the right way to discuss a very important and serious issue. Do you think there should be more safeguards on AI bots that interact with children? No, I'm sorry. This is why we get into a problem in this country, because we go for these simplistic solutions. Thank you, Mr. Hilton. Mr. Steyer, do you have an answer for me? And it causes problems that are unintended. And we need to have a serious conversation about a very serious issue. We have to protect children, but do it in a sensible way that works. Look at these policies that are being implemented around the world. Okay, Mr. Hilton, I have to move forward. Like in Australia, they don't work. [75:37] It's really not. [75:51] Yes or no questions. They're a little bit longer. Sometimes. [77:08] This state is desperate for change. We cannot have another four years of one -party rule. We need some balance. The only choice for change, apart from myself, is Chad. [80:31] I think we get it, Tom. You're a billionaire. Congratulations. Look, I get on with Tom. I get on with everyone on this stage, and we're all here for the same reason. We love this state, and we want it to be the state that once again offers young people the opportunity to make your life here better than anywhere else in our country. The truth is that we've gone off track. We've got one party rule now for 16 years. The results have been such a disappointment. It is time for some balance. We need some balance in our system. No more one party rule. And the reason that I can make the change happen is precisely because I get on with people from all different backgrounds. I'm not an ideologue. I'm pragmatic. I'm a problem solver. Most of my career has been in business, but I have experience working inside of a government. Above all, I know how to work with people to make change happen. That's what we need in California. Common sense, practical ideas to turn things around and restore the California dream.

---
snapshot_id: 615f8a49-c77e-51e3-9cc2-41989305b30c
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/making-californias-public-colleges-affordable-again

Saved from https://stevehiltonforgovernor.com/policies/making-californias-public-colleges-affordable-again (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA’S PUBLIC COLLEGES AFFORDABLE AGAIN ← POLICY ARCHIVE MAKING CALIFORNIA’S PUBLIC COLLEGES AFFORDABLE AGAIN The Califordable Hilton-Romero Plan to Cut Costs, Cut Bureaucracy, and Help Students Get Ahead THE PROBLEM California’s public colleges were supposed to be a ladder up. For too many families, they have become just another cost trap driven by rising tuition and outdated timelines that force families to pay more. Costs keep going up, and families have no way to keep up. At the California State University system, undergraduate tuition is now $6,450 a year, with another increase already scheduled. At the University of California, tuition for new in-state undergraduates is $15,588, and the university estimates the total annual cost can reach about $47,000 once housing, meals, books, transportation, and other expenses are included. Even California Community Colleges, often sold as the cheap option, charge $46 per unit in enrollment fees, or $552 for a full-time 12-unit semester, before books, commuting, and everything else. And the problem is not just price. It is waste and falling standards. Students are pushed into longer timelines, cannot get the classes they need, and lose time and money trying to transfer credits. In the California State University system, only about 35 percent of first-time students graduate in four years. HOW DEMOCRATS BROKE IT This happened on the Democrats’ watch. After years of one-party rule, California’s public colleges have gotten more expensive, more bloated, with lower standards and less accountability. Tuition keeps going up, costs keep rising, and Democrats have done nothing to stop it. Instead of forcing these institutions to control costs and modernize how students move through college, Democrats protected the status quo. Families pay more. Students wait longer. Bureaucrats win. THE PLAN OFFER FASTER, LOWER-COST THREE-YEAR DEGREES California should not be trapping students in a four-year timeline that drives up costs and delays careers. This plan will push for three-year degree options and accelerated pathways so students can enter the workforce sooner and avoid paying for unnecessary time in school. Students should have the choice to move faster, graduate sooner, and start building their careers. STOP TUITION FROM GOING UP This plan will freeze in-state tuition at California’s public colleges while forcing the system to cut waste and lower costs. TAKE CONTROL AND LEAD ON ACCOUNTABILITY As governor, Steve Hilton will use every tool available to force reform across California’s public colleges, working with his running mate for lieutenant governor, Gloria Romero. The lieutenant governor is the only elected official who serves on the governing boards of the University of California, the California State University system, and the California Community Colleges, and will show up, lead, and be a visible voice for affordability and accountability. SHOW FAMILIES WHERE THE MONEY GOES Clear campus-by-campus reporting, independent audits, and full program reviews will expose waste, ensure real value for taxpayers, and focus resources on programs that meet clear standards and lead to career-ready outcomes. This includes reviewing student housing to ensure it is used efficiently and prioritized for students who actually need it. MAKE COMMUNITY COLLEGE TRANSFER ACTUALLY WORK AND PUT CALIFORNIA STUDENTS FIRST Simpler transfer rules and stronger credit portability will ensure students do not lose time and money. Public universities should prioritize California students in admissions so those who grew up here have a fair shot at attending. That also means fixing the pipeline leading into college, so students are prepared when they arrive and not forced into remedial courses that add cost and delay. The administration will implement a “Kindergarten-to-College Pipeline Strategy” to ensure students are prepared at every stage. RESTORE STANDARDS AND ACCOUNTABILITY IN PUBLIC COLLEGES Public colleges should restore clear standards, real accountability, and a focus on results, not bureaucratic sprawl. That means prioritizing programs that lead to real careers and good jobs, enforcing merit-based decisions, protecting non-discrimination under Proposition 209, ensuring student safety during protests, and upholding fairness in women’s sports. CONCLUSION California’s public colleges should help young people get ahead. Instead, too many students are paying more, taking longer, and getting less. The Hilton-Romero administration will take on the bureaucracy, demand accountability, stop the cost spiral, modernize how students move through college, and make California’s public colleges affordable again. ← Back to all policies

---
snapshot_id: c4c2a233-a5ff-563c-97f0-94a83cc2b413
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/califordable-newsoms-vmt-bombshell

Saved from https://stevehiltonforgovernor.com/policies/califordable-newsoms-vmt-bombshell (rendered page text, built-in browser, 2026-10-07) POLICY CALIFORDABLE: NEWSOM’S VMT BOMBSHELL ← POLICY ARCHIVE CALIFORDABLE: NEWSOM’S VMT BOMBSHELL UP TO $1,350 A MONTH FOR 20 YEARS JUST TO BUILD A HOME 1. THE PROBLEM California has made it too expensive to build homes, and now AB 130 makes that problem worse. Signed into law in 2025 by Gavin Newsom, AB 130 was sold as a way to make it easier to build housing. Instead, it adds a new layer of cost through its Vehicle Miles Traveled (VMT) provisions. VMT is a metric the state uses to estimate how much people living in a new development are expected to drive. Under AB 130, if a project is expected to generate more driving, developers must offset that impact. The law creates a new statewide VMT Mitigation Bank , allowing developers to pay into a government-managed fund instead of reducing driving directly. That fund is used to finance state-approved projects like dense housing or transit-oriented development, based on formulas set by regulators. In other words, the state is setting up a system where the cost of building housing is determined by regulatory formulas rather than the market. The key point is this: the amount developers must pay is not fixed in law. It will be determined by state agencies through a complex system of credits, formulas, and guidance. Some estimates suggest these charges could reach $16,200 per year per unit — or up to $1,350 per month for 20 years for a single home or apartment. That is not a minor fee. That is a major new cost layered onto every new home. Those costs don’t disappear. They get passed directly to buyers and renters. Some projects won’t get built at all. The ones that do will cost more. At a time when California should be lowering costs and building more homes, this moves in the opposite direction. 2. THE PROBLEM DEMOCRATS CREATED California Democrats made housing expensive to build in the first place. Restrictive zoning, CEQA abuse, endless permitting delays, and rising compliance costs have choked off supply and driven up prices across the board. People adjusted to that reality. When homes are scarce and expensive, families make tradeoffs. They live where they can afford to live. They commute. They do what they have to do to make it work. Now, instead of fixing the root problem, Democrats are layering on a new system of VMT charges through a state-run mitigation bank that penalizes those choices. This is the same pattern: create a problem through bad policy, ignore the cause, and then impose new costs on the consequences. You cannot make housing affordable by making it more expensive to build. 3. STEVE’S PLAN Steve Hilton will focus on one thing: lowering the cost of building homes and stopping this new VMT scheme from driving prices even higher. 1. END THE WAR ON SINGLE-FAMILY HOMES AND MAKE IT EASIER TO BUILD Make it easier to build the kinds of homes families actually want, including single-family homes, and allow growth in areas that can support it. State government will stop acting as a barrier. Agencies will be directed to move projects forward, cut delays, and stop using regulations to stall or kill housing. 2. SHUT DOWN THE VMT COST SCHEME AT THE SOURCE The size of these charges will be determined by the Office of Land Use and Climate Innovation (LCI) , which is responsible for setting the rules for the VMT Mitigation Bank. Steve will direct LCI to set the cost of VMT credits at zero , effectively eliminating these charges. That means rewriting the formulas and credit system so this program cannot be used to impose new costs on housing. 3. BLOCK AGENCIES FROM TURNING VMT INTO A BLANK CHECK He will direct state agencies, including Caltrans , to revise their guidance so VMT cannot be used to justify excessive mitigation requirements or new fees on housing projects. The rules will make clear that projected driving cannot be used as a blank check to add costs. 4. CONCLUSION California’s housing crisis is the result of policy choices that made it too difficult and too expensive to build homes. AB 130 adds a new layer of cost through a complicated system of VMT credits, mitigation payments, and state-set pricing formulas that will be defined by regulators, not voters or the legislature. Whether this becomes a major new cost on housing will depend on how those rules are written. The solution is clear: lower the cost of building and stop adding new ones. Build more homes. Get government out of the way. California doesn’t need more bureaucratic schemes. It needs fewer barriers, lower costs, and more homes. ← Back to all policies