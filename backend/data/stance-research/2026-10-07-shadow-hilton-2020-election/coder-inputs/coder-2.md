You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-2020-election/labels/coder-2.json. Write JSON only, matching
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

### topic_key: 2020-election
topic_id: b5260e5a-5576-4071-8b2a-088af8d1f9eb  served_revision_id: 81920cf6-9a30-4c5c-82b1-5f2c16cda95c
Question: What is your view of the outcome of the 2020 presidential election?
  1. The election was fair and Joe Biden won legitimately.
  2. Joe Biden won, but the election had real problems worth fixing.
  3. There was some fraud, but not enough to change the result.
  4. Fraud or irregularities may have been enough to change the result.
  5. The election was stolen from Donald Trump through widespread fraud.

#### Annex

# 2020-election — served revision 81920cf6-9a30-4c5c-82b1-5f2c16cda95c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. No gold item exists on this topic
yet; every reading below is a drafter's.

**Question:** "What is your view of the outcome of the 2020 presidential election?"

**Orientation:** off-axis — a **belief** ladder, not a government-action ladder. Rung 1 accepts the
certified result without reservation, rung 5 says it was stolen. The rungs order **how far the
person doubts the certified result**. No rung asks what government should do.

**Levels with a lever:** federal, local, state, in the sense that records count at each level. No
officeholder can change a past event; the evidence is mostly own words. Records exist too: objections to electoral votes
(Congress), audit, decertification or elector resolutions (state), certification votes (local
election boards).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "certification", "certify" or "decertify", "electoral count", "objection",
"Electoral Count Act", "alternate electors", "forensic audit", "irregularities", "rigged",
"stolen", "election integrity", "legitimate", "the will of the voters".

1. **"The election was fair and Joe Biden won legitimately."**
   - Means: the 2020 election was fair, and its winner won legitimately.
   - Operative clauses: [a] the election was fair; [b] Biden won legitimately.
   - Establishing evidence looks like: own words that say both. A vote to certify, or against an
     objection, shows acceptance of the result but does not separate rungs 1, 2 and 3 →
     `direction-only` _(proposed)_.
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 when the person also backs election-security changes. A call to
     improve future elections is not a statement that 2020 "had real problems" → it does not move
     the person to rung 2 _(proposed)_.

2. **"Joe Biden won, but the election had real problems worth fixing."**
   - Means: the result stands, but the 2020 election had real faults that need correcting.
   - Operative clauses: [a] Biden won; [b] the 2020 election had real problems worth fixing.
   - Establishing evidence looks like: own words that accept the result **and** name problems in the
     2020 election. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because "problems" can mean fraud. Rung 2's problems are faults
     (administration, rule changes, delays); a person who says fraud occurred is rung 3 or above.

3. **"There was some fraud, but not enough to change the result."**
   - Means: some fraud happened in 2020, but the result would have been the same.
   - Operative clauses: [a] some fraud occurred; [b] not enough to change the result.
   - Establishing evidence looks like: own words that say both. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 when the person says fraud occurred and does not say whether it
     changed the result. That is [a] only → `compound-partial`, not rung 4.

4. **"Fraud or irregularities may have been enough to change the result."**
   - Means: the person is unsure whether the result was right, because fraud or irregularities may
     have changed it.
   - Operative clauses: [a] fraud or irregularities; [b] possibly enough to change the result.
   - Establishing evidence looks like: own words that the outcome is in doubt because of fraud or
     irregularities.
   - Levels that hold a lever: none; own words. Records: see hard cases.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because "may have" and "was" are close. Rung 5 is certainty; doubt
     is rung 4.

5. **"The election was stolen from Donald Trump through widespread fraud."**
   - Means: the person says the election was taken from its rightful winner by widespread fraud.
   - Operative clauses: [a] the election was stolen (the result is wrong); [b] through widespread
     fraud.
   - Establishing evidence looks like: own words that say the election was stolen, or that Trump
     won, by fraud.
   - Levels that hold a lever: none; own words. Records: see hard cases.
   - Known chair-shaped instruments: _(none on file)_.
   - "Stolen" or "rigged" with no mechanism named → `compound-partial`: it meets [a] but not [b]
     "through widespread fraud" (H14) _(ruled 2026-10-01)_.
   - A claim that it was stolen by something other than fraud (rule changes, media, courts) meets [a]
     but not [b] → `compound-partial` _(proposed)_.

**Hard cases:**
- **Objections and electoral-count votes.** A vote to object to a state's electoral votes shows doubt
  about that count. It does not separate rung 4 from rung 5, and an objection can rest on rule
  changes rather than fraud → `direction-only`, unless the person's own explanation of the vote places it
  _(proposed)_.
- **Lawsuits and amicus briefs** (Q8 `record`): the legal claim must match the rung. A claim that
  states changed election rules unlawfully is not a claim of fraud → `direction-only` at most
  _(proposed)_.
- **Audit and certification votes.** A vote for an audit, or against certifying, shows doubt but names
  no conclusion → `direction-only` _(proposed)_.
- **Dodges.** "I'm focused on the future", "Biden is the president", "that's been litigated" do not
  state a view of the outcome → V4 `rhetorical`; BLANK `no-evidence` if nothing else survives. A
  blank here is correct.
- **Time (V5).** A person's view may have changed since 2020. The newest evidence governs; older
  passages are `superseded-by-later`. A statement outside the election cycle goes to review.


## Sources

---
snapshot_id: 1b2018dd-4490-5f3d-8699-326d1abe7569
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD ← POLICY ARCHIVE MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD THE PROBLEM California should be leading the future of digital finance. Instead, we are driving innovation, investment, and talent out of our state. For decades, California was the best place in the world to build transformative technologies. Today, companies and entrepreneurs are increasingly looking elsewhere because of overregulation, political uncertainty, and rising costs. The global race for leadership in digital assets and blockchain technology is already underway. States like Texas and Wyoming, along with other countries, are competing aggressively for jobs, investment, and innovation. California has every advantage needed to lead, but bad policy decisions are pushing that opportunity away. Digital assets, blockchain networks, and stablecoins are becoming an important part of the future of finance and payments. If California falls behind, America falls behind with it. WHY THIS IS HAPPENING California’s leadership has adopted a “regulate first, figure it out later” approach to innovation. Instead of creating clear rules that encourage responsible growth, policymakers have created uncertainty that drives companies and investment elsewhere. Companies should not have to guess what the rules are before they invest and build here. California has already seen what happens when government makes it too difficult to build, invest, and innovate. We should not repeat those mistakes with one of the most important emerging technologies in the world. THE PLAN 1. CREATE CLEAR RULES FOR DIGITAL ASSETS California should provide transparent and predictable rules for digital asset companies instead of overly broad regulations that create confusion and drive investment elsewhere. California should clean up the Digital Financial Assets Law and ensure state rules complement emerging federal frameworks instead of conflicting with them. 2. PROTECT PARTICIPATION IN THE DIGITAL ECONOMY Californians should be free to securely control their own digital assets and lawfully participate in blockchain networks without unnecessary government interference. California should end its misguided restrictions on staking and allow Californians to participate in lawful staking services. 3. SUPPORT BLOCKCHAIN INNOVATION AND KEEP CRYPTO JOBS IN CALIFORNIA California should be the best place in the world to build crypto companies and blockchain technology. We should lower barriers to building and stop driving companies, investment, and talent to other states and countries. 4. PROTECT CONSUMERS AND CRACK DOWN ON FRAUD Government has a responsibility to aggressively prosecute scams, fraud, and criminal abuse. But enforcement should target bad actors, not crush legitimate innovation and responsible companies. CONCLUSION California became successful because we built the future instead of fearing it. We have the talent, entrepreneurs, and companies needed to lead the world in digital assets and blockchain technology. But leadership requires a governor who supports growth, encourages innovation, and creates clear rules instead of uncertainty and bureaucracy. Instead of driving opportunities away, California should be the place where the future is built. ← Back to all policies

---
snapshot_id: cd62ec99-5920-53a5-aa26-c4be7084181d
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan

Saved from https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan (rendered page text, built-in browser, 2026-10-07) POLICY EMERGENCY ELECTION COUNT ACCELERATOR PLAN ← POLICY ARCHIVE EMERGENCY ELECTION COUNT ACCELERATOR PLAN INTRODUCTION California should be able to conduct elections that are both secure and timely. Every legal ballot should be counted, but voters should not have to wait weeks to find out the outcome of an election. The state routinely mobilizes personnel and resources during emergencies. When election offices face massive post-election backlogs, California should do the same. By temporarily assigning qualified state employees, deploying rapid-response support teams, and funding expanded county operations, California can accelerate ballot processing, reduce delays, and provide voters with election results more quickly while maintaining the integrity and security of the process. California is the fourth largest economy in the world, and home of the technology industry that has so dramatically changed the world. When it comes to elections, it’s time we acted like it. Ultimately, California needs broader reforms to its election system. But in the short term, for the primary election of June 2nd 2026, we cannot continue with a process that leaves millions of voters waiting weeks for results. Governor Newsom should immediately issue an emergency Executive Order designed to bring ballot-processing backlogs to a close as quickly as possible, with the goal of guaranteeing complete and verified election results within 48 hours of the deadline for receiving mail-in ballots: final election results by 8pm on Thursday 11th June. If India can count over 600 million ballots in 24 hours, surely California can count a tiny fraction of that number in twice the time. A SYSTEM THAT ISN’T WORKING California’s election delays are not an isolated problem. They are yet another symptom of a government that has stopped delivering basic results. Californians have been promised a high-speed rail project that has barely begun after years of delays and billions of dollars in spending. State and local governments have spent billions addressing homelessness while encampments remain a visible crisis in communities across the state. Now California once again finds itself waiting weeks for election results after fewer than ten million ballots were cast. It is an extraordinary and unacceptable shambles. California has become a global laughing stock for its inability to conduct elections in an efficient, timely manner. Californians have been conditioned to accept delays that would be unacceptable in almost any other area of government. Elections should be secure, accurate, and timely. The fact that voters can wait weeks for final results is evidence that the system is not functioning as it should. This is not about counting fewer ballots or lowering standards. It is about basic governing competence, which has completely collapsed in California, it now seems. Voters deserve an election system that is both accurate and efficient. PLAN FOR CHANGE California’s election laws should be reformed to deliver faster, more transparent, and more trustworthy election results. The following reforms would dramatically accelerate election results while preserving election integrity: Require vote-by-mail ballots to be received by Election Day rather than accepted for several days afterward if postmarked by Election Day. Mail ballots only to voters who specifically request them rather than automatically sending ballots to every registered voter. Provide free voter identification cards to all registered voters and require identification for in-person voting. Expand pre-election ballot processing so counties can verify signatures, prepare ballots for tabulation, and complete administrative review before Election Day. None of these reforms would eliminate the need to count every legal ballot. But together they would dramatically reduce post-election delays, improve transparency, strengthen confidence in the process, and move California toward a system where voters know the outcome of elections in hours, not weeks. EMERGENCY ELECTION COUNT ACCELERATOR CORPS While broader reforms are implemented, Governor Newsom should act immediately to accelerate the count in the primary election of June 2026. The Governor should establish an Emergency Election Count Accelerator Corps by temporarily deploying available state employees from non-essential administrative positions to county election offices experiencing significant ballot-processing backlogs. These personnel would work under the supervision of county Registrars of Voters and assist with ballot processing, administrative review, data entry, ballot preparation, and other support functions permitted under existing law. The state should also create regional election surge teams that can be rapidly deployed to counties facing the largest backlogs, ensuring staffing resources are directed where they are needed most. In addition, California should establish an Election Count Accelerator Fund to reimburse counties for overtime, expanded shifts, weekend operations, and other temporary costs associated with accelerating ballot processing after Election Day. The proposal would not change election laws, security procedures, or vote-counting standards. Every ballot would still be processed according to existing law and under the authority of local election officials. The goal is simple : count every legal ballot , maintain election integrity , and deliver timely results that voters can trust . Specifically , ensure that in the primary election of June 2026, Californians have complete and verified results within 48 hours of the deadline for receiving mail – in ballots . Final election results by 8 pm on Thursday 11 th June . ← Back to all policies

---
snapshot_id: 371e1754-24db-5959-9804-4a08f2f43e84
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud

Saved from https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD ← POLICY ARCHIVE OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD THE PROBLEM The California State Auditor has warned that weak oversight has opened the door to organized healthcare fraud. Criminals can bill for care that never happened, including by using stolen patient information. Taxpayers lose the money, and the elderly and disabled people these programs are supposed to help can be left without the care they need. Stopping that waste is money the state can save. Steve Hilton and citizen investigator Eric Nissen went to a listed home-health agency in Hollywood and found a locked building, no entry listing for the agency, and a published telephone number that could not be reached. They found those red flags in minutes. State regulators need to check that agency's records and establish whether it has billed taxpayers and whether patients received care. It should not take a citizen knocking on the door to get those questions asked. HOW WE GOT HERE In 2022, the California State Auditor identified signs of large-scale, organized hospice fraud in Los Angeles County. One building in Van Nuys housed more than 150 licensed hospice and home-health agencies, more than the building could hold. The auditor found inadequate checks on licenses and staff credentials, slow investigations, and failures to coordinate between state departments. Those licensing failures sit with the California Department of Public Health. Medicare billing oversight sits with the federal Centers for Medicare & Medicaid Services. The officials who ran those systems owe taxpayers an explanation. Herb Morgan, who is running for State Controller, estimates billions of dollars in potential fraud, waste, and improper payments in Medi-Cal and In-Home Supportive Services, or IHSS. In his white paper, the Medi-Cal figure uses a roughly 10 percent improper-payment band drawn from federal CMS Payment Error Rate Measurement ranges. The IHSS figure uses 12 to 15 percent, reflecting self-reported hours and limited verification. Those are exposure estimates, not a count of proven fraud, and they are the starting point for where to look. California already has provider screening and electronic visit verification. Steve will require the agencies to use those records to check the care being billed and stop fraudulent payments. STEVE'S PLAN On Day One, as part of Operation Zero Waste, Steve will direct the Departments of Health Care Services and Public Health to review high-risk home-health and hospice agencies together. Investigators will check the owners and staff credentials, make unannounced visits to suspect offices, and match billing records to actual patients and services. Agencies must be able to show who delivered the care. When the evidence supports it, the state will suspend Medi-Cal payments, revoke licenses, and refer cases for prosecution. Investigators will trace connected companies so an excluded operator cannot simply reopen under another name, and send evidence of Medicare fraud to federal authorities. For IHSS and home-health visits, Steve will require closer checks of the hours claimed against authorized care and existing visit records. Repeated manual changes, impossible hours, and overlapping claims will trigger review and direct confirmation with the patient or an authorized representative. Live-in caregiver exemptions will be checked in suspicious cases. State agencies will match claims against death records, hospital stays, and excluded-provider lists, blocking clearly invalid claims such as services dated after a patient's death. Families providing genuine care will keep getting paid, with a prompt way to correct errors that could interrupt necessary care. Steve will require additional review before payment for providers with serious billing red flags, then extend those checks to medical transport, equipment, and behavioral-health services. His administration will pursue repayment from fraudulent providers and work with state and federal prosecutors on organized schemes. Medi-Cal health plans will have to account for recovered overpayments, with sustained reductions in improper spending reflected in future payments to plans. Otherwise, taxpayers could keep paying the same amount while the plans pocket the savings. Steve will work with Herb Morgan to check the financial results. When elected Controller, Herb will use the office's independent audit authority to examine high-risk payments and review the savings. He will publish the results under a radical-transparency standard: provider payments, recovery amounts, and exception patterns available to the public, with patient and caregiver identities fully protected. Steve is aiming for $5 billion a year in net savings to California's budget once the changes are in place. Public reports will show the California savings after enforcement costs, with federal savings and one-time recoveries listed separately. Only money California can save every year will be counted as ongoing savings. Within the first 100 days, inspections of suspect agencies and tighter checks on their claims will be underway. Over the following nine months, the administration will strengthen IHSS verification and connect the records needed to catch bad claims before payment. Within 18 months, the controls will extend across the targeted services. Steve will seek any legislation or federal approvals needed to finish the job, and publish the results as the work proceeds. A BETTER WAY FORWARD Families looking for home care should be able to reach the provider and trust that someone will turn up. Taxpayers should be able to see what they are paying for, without seeing anyone's medical record. Steve's administration will make providers and the departments overseeing them answer for that money. Radical transparency will put the financial results in public, and the savings will be reported in public. ← Back to all policies

---
snapshot_id: e63ad754-a8e5-5a0a-9eca-12abb5af4f69
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business

Saved from https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business (rendered page text, built-in browser, 2026-10-07) POLICY ENDING THE WAR ON SMALL BUSINESS ← POLICY ARCHIVE ENDING THE WAR ON SMALL BUSINESS Small businesses create jobs, keep communities alive and give people the chance to build something of their own. They are an essential part of social mobility and the opportunity to build generational wealth. But the Democrats running California have spent years treating small businesses like a cash machine…or a problem to be managed - rather than a beautiful, vital part of our economic life and social fabric. Owners can owe the state $800 before earning a dollar. They spend hours dealing with rules nobody can understand and money defending extortionate shakedown lawsuits over footling technical discrepancies. Rents, energy and insurance bills keep rising, hiring gets more expensive and projects wait years for approval. It all adds up. Enough is enough. Steve Hilton is the candidate of small business, for small business. ‘Small business owner’ is his actual designation on the ballot. Steve has started and run a range of small businesses, including restaurants. He knows exactly what it’s like to try and stay afloat in the face of tiny margins, tough economic conditions and endless harassment and nonsense from government and bureaucratic agencies. Steve will end the Democrat war on small business, and give this essential part of our economy the freedom and support it needs. California’s small business owners have never had as passionate and committed a champion as Steve Hilton will be as governor. 1. CUT CALIFORNIA’S REGULATIONS BY MORE THAN HALF California has more than 420,000 regulatory requirements and prohibitions. By the end of his first term, Steve will bring that number below 200,000. Each state agency will have a public reduction target and will have to show its progress. A regulation should stay on the books only if it protects against a real harm and its benefit justifies its cost. Any major regulation expected to cost Californians $50 million or more will require an independent cost analysis and a public vote by the Legislature. Elected lawmakers should have to specifically justify regulations that impose undue costs on the public, with the default assumption that they are not justified. Starting a business will no longer mean chasing different agencies for registrations, licenses and permits. California will create one place to complete the state process, recognize comparable occupational licenses from other states and eliminate licenses that no longer serve a public-safety purpose. 2. END SHAKEDOWN LAWSUITS Trial lawyers and unions have turned California law into an extortionate shakedown racket. Small businesses are threatened with ruinous litigation over footling technical discrepancies, obviously manufactured complaints, and failure to comply with insane, pointless, bureaucratic processes created solely to generate more work for the trial lawyers who bribe the politicians that write these ridiculous laws. The legal process is engineered in a way that forces businesses to settle even when nobody has suffered real harm. It’s disgusting. Steve will enact real tort reform. PAGA will be ended by actually following the law as written, with the Labor Commissioner taking the first step in labor law enforcement, as laid out in Steve’s End PAGA plan, published last year. Employers who cheat their workers will still be punished. Private trial lawyers will no longer bring cases in the name of the state and collect enormous fees. A small business that makes an honest first-time mistake will receive clear notice and a reasonable opportunity to correct it before fines or lawsuits begin, provided the violation was not deliberate and caused no serious harm. The same protection will apply to construction-related accessibility claims. Businesses will still have to make their properties accessible, but an owner who promptly fixes a violation will not be forced to pay state statutory damages and attorneys’ fees. Fraud, repeated violations and conduct that puts people in danger will not qualify. 3. CUT THE COST OF EMPLOYING PEOPLE California forces private employers to navigate a separate workplace safety bureaucracy even though a national OSHA standard already exists. Steve’s Safe and Califordable Workplaces plan will move private employers to the federal OSHA baseline. California will keep a state plan for state and local government workers. This will reduce the cost of employing people, especially for small and fast-growing businesses. For a first-time, non-willful violation by a small business, the first response will be help rather than a fine. The business will receive plain-English guidance and 30 days to correct the problem. Written compliance questions will be answered within five business days. Employers who knowingly put workers in danger, retaliate against workers or repeatedly ignore violations will face tough enforcement. California-only rules that do not make workers safer or merely duplicate federal requirements will be repealed or rewritten. Workers’ compensation is supposed to help people injured on the job. Too much of the money is swallowed by lawyers, delays and fraud. Steve will set a first-term goal of cutting California’s workers’ compensation premium burden by at least 25 percent. Legitimate claims will move faster, the legal and administrative costs that drive up premiums will be cut, and fraud will be prosecuted. State Fund will also be reviewed and reformed if it is not lowering costs and helping injured workers. 4. ABOLISH THE $800 SMALL BUSINESS TAX California charges LLCs and many corporations at least $800 every year, even if the business loses money or never opens its doors. Steve will abolish this tax and veto any new state tax or fee that raises the cost of starting or running a small business. A business that earns no profit should not owe the state $800 simply for existing. 5. PAY OFF CALIFORNIA’S UNEMPLOYMENT DEBT California’s federal unemployment debt is driving up payroll taxes for employers every year through FUTA taxes (Federal Unemployment Tax Act). The most recent level is a 2.1% surcharge for every employee. This is an absolutely massive scandal, on so many levels. First, the tens of billions of dollars paid out by the Employment Development Department (EDD) should never have been needed in the first place: it was all a consequence of the cruel and counter-productive covid lockdowns, totally unjustified on any public health grounds, that viciously targeted small businesses while leaving many large businesses able to stay open. Secondly, the utter, disgraceful incompetence of the EDD led to over $30 billion being stolen in fraud, error and identity theft, including checks sent to prisoners on death row and United States Senators. It was an unforgivable dereliction of duty by Xavier Becerra’s Sacramento machine, and still no-one has been held accountable. Third, the gross negligence and incompetence of the Sacramento machine meant that California was the only state to not pay back its federal loan. And now every small business in our state is paying the price for the uselessness of our politicians and their appointed bureaucrats. Steve will pay off the debt by the end of his first term using savings from elsewhere in state government. Small businesses who were first penalized by the covid lockdowns should not be penalized again with a tax increase. Employers who did not create the debt will not be handed another state tax increase to cover it. Steve will also pursue legal remedies against Julie Su, now Deputy Mayor for Economic Justice under Mayor Mamdani in New York, and reduce the pay of all senior EDD officials who were working in the Department during this scandal. 6. PROTECT MAIN STREET FROM THEFT Retail theft is not victimless. Small-business owners pay through lost inventory, higher insurance premiums and added security costs. Proposition 36 will be fully funded and implemented, including the enforcement and treatment voters approved. Business owners should not have to accept theft as another cost of operating in California. Beyond these specific measures to help small business, Steve will cut the taxes, rules, lawsuits and other costs that make it so hard to run a small business in California. In particular, Steve’s other plans to cut energy costs will make a huge difference to every small business in California. Small businesses pay California’s high energy costs through their own gasoline and electricity bills and through the price of everything delivered to them. Steve’s Califordable energy plan will increase production in California and reverse rules that drive investment out of the state. The cost of every proposed energy regulation will have to be disclosed before it is adopted. California will not impose a vehicle mileage tax. The goal is $3.00 gas and cutting electric bills in half. ← Back to all policies

---
snapshot_id: 50650858-cfdb-5630-a690-37898f81e50e
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/bring-hollywood-home

Saved from https://stevehiltonforgovernor.com/policies/bring-hollywood-home (rendered page text, built-in browser, 2026-10-07) POLICY BRING HOLLYWOOD HOME ← POLICY ARCHIVE BRING HOLLYWOOD HOME Steve Hilton’s Plan to Revive and Grow California’s Film and Television Industry THE PROBLEM California invented the entertainment business. Hollywood became the global center for film and television, supported by world-class talent, crews, studios, and infrastructure. But that advantage is slipping away. Production is leaving California for states and countries offering better incentives, lower costs, and more predictable systems—including Georgia, New York, New Jersey, New Mexico, Canada, the UK, and Australia. This is not about celebrities—it’s about jobs. Thousands of middle-class workers depend on the industry: Camera operators Electricians Editors Set builders Drivers Costume designers Small businesses supporting production When productions leave, those jobs leave too. The damage is already clear: Roughly 51,000 jobs lost in three years Soundstage occupancy in Los Angeles has dropped from over 90% to about 62% The lights are literally going out in Hollywood. WHY THIS IS HAPPENING California has fallen behind competitors that offer: Stronger, more flexible incentives Faster approvals Greater certainty for producers While California increased its tax credit program to $750 million annually, the system still has major flaws: Rigid application windows Complex categories Limited access for smaller productions Other regions operate faster, simpler, and more competitive systems—often without caps. California is still acting like Hollywood has nowhere else to go. It does. THE GOAL Restore California as the best place in the world to make film and television— Bring Hollywood Home . The goal is not nostalgia—it’s economic reality. By the 2028 Olympics in Los Angeles, California should reestablish itself as the global center of production. This means: Rewarding productions that hire California workers Supporting local facilities and communities Competing globally instead of managing decline THE PLAN 1. MAKE CALIFORNIA COMPETITIVE AGAIN California must compete globally with stronger, more reliable incentives. Key changes: Move to an uncapped, open production incentive system Cover both above-the-line and below-the-line costs Include post-production work This ensures producers choose California because it makes business sense—not because they win a lottery. The plan also explores: Federal tax incentives Temporary “kick-start” incentives Enhanced incentives for key zones and independent productions 2. GIVE PRODUCERS CLARITY AND CERTAINTY Production requires predictable timelines—not bureaucratic delays. Reforms include: Continuous, rolling approval system Automatic certification within 30 days Streamlined permitting processes Additional steps: Enforce deadlines on agencies Refund fees if deadlines are missed Appoint a Governor’s Expediter to cut through bureaucracy No more waiting. No more guessing. 3. PROTECT INDEPENDENT AND MID-SIZED PRODUCTIONS Current programs often favor large studios while smaller productions struggle. The plan will: Reserve funding for independent and mid-budget projects Ensure smaller producers are not crowded out A healthy industry needs both major productions and independent creators. 4. MAKE THE INCENTIVE REAL Tax credits must translate into real financial value. Reforms include: Expanding direct rebates Improving transferability Ensuring credits are usable and bankable The plan also calls for federal partnership to compete internationally, including: National production incentives Support for major events (Olympics, World Cup) Investment in studio and venue infrastructure 5. PROTECT CALIFORNIA’S CREATIVE FUTURE The issue isn’t just production—it’s ownership and control. Independent creators increasingly lose rights and long-term value through financing structures. The plan will: Support creative ownership Strengthen independent production Work with industry stakeholders to maintain a balanced ecosystem California should be a place where creators build and own , not just work. THE BOTTOM LINE Hollywood should not be leaving Hollywood. California still has: The talent The workforce The infrastructure The global brand What it has lacked is leadership. Bring Hollywood Home is about restoring: Jobs Opportunity One of California’s defining industries California invented the entertainment business. It’s time to win it back. ← Back to all policies

---
snapshot_id: 791f9764-6b84-5a9e-9bf3-ca1108264067
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/abolish-the-dmv

Saved from https://stevehiltonforgovernor.com/policies/abolish-the-dmv (rendered page text, built-in browser, 2026-10-07) POLICY ABOLISH THE DMV ← POLICY ARCHIVE ABOLISH THE DMV A CALIFORDABLE Plan to Cut Vehicle Registration to $73, End DMV Lines, Eliminate Bureaucracy, and Turn Empty Offices Into Opportunity OVERVIEW California is a car state. For most people, a car is how they get to work, get their kids to school, run a business, and live their lives. Yet something as basic as renewing a registration can still mean taking time off work to deal with the hated DMV. California spends $1.46 billion a year on a department with 170 field offices. It is a huge, old-fashioned monopoly that treats the taxpayers who fund it with complete contempt. It is the miserable symbol of California's bloated, costly nanny state bureaucracy, bossing people around while charging a fortune for the privilege. The DMV has trained people to expect delays, confusing paperwork, and bad service. Most states do not have a stand-alone DMV - California is one of only ten or so states with a separate DMV bureaucracy. Of course it is important that the state has secure records, legitimate licenses, and strong fraud prevention. It does not need to make people stand in line all day to receive rude, surly - and insanely slow - service for things that in other countries and states are handled entirely online. Steve Hilton will abolish the DMV, set annual vehicle registration at a flat $73, and give Californians better, cheaper options. THE PROBLEM The DMV is built around the bureaucracy, not the public. If a transaction cannot be completed online, Californians have to fit it into the state's schedule. They take time off work, arrange child care, miss appointments, and hope the person behind the counter can solve the problem that day. If the service is slow, confusing, or unhelpful, there is nowhere else to go. The DMV has a monopoly. For years, Democrats have tried to patch this failure with another website, another kiosk, another appointment system, or a new set of office hours. None of that fixes the basic problem. The public is still expected to work around the government instead of the government working around the public. And California’s basic $73 vehicle registration fee is buried under a value-based vehicle tax, transportation add-ons, and local surcharges. Drivers can end up paying $500, $600…even $1,000 or more, while in most other states, registration is under $100. California already uses kiosks and private partners for some transactions, but the better option can come with an additional fee. People who can afford it sometimes buy their way out of the line. Everyone else is stuck. Other states have shown a better way. Colorado routes most title and registration work through county offices. Arizona allows regulated local providers to handle registrations, titles, driver's licenses, and road tests. California can do the same while keeping the state in charge of security and standards. STEVE HILTON'S PLAN: ABOLISH THE DMV The point is simple: get rid of the DMV bureaucracy and buildings, not the services people need. Steve Hilton's plan keeps the state responsible for secure records and safety, but gives Californians more convenient and affordable ways to get things done. 1. ABOLISH THE DMV AS A STAND-ALONE DEPARTMENT Steve will order a full audit of every DMV function, office, lease, contract, and cost. It will report within three months. He will then send the Legislature a No More DMV Act to eliminate the Department of Motor Vehicles. The state will keep a lean records and safety operation within existing government. Its job will be to maintain the statewide database, issue state credentials, protect personal information, investigate fraud, and enforce safety rules. It will not run a giant network of public waiting rooms. The goal is a much smaller state back-end that does the work only government must do. 2. MAKE DMV SERVICES LOCAL AND CUT REGISTRATION TO $73 Routine title, registration, plate, and renewal transactions will move to county offices and certified local service centers. Californians should be able to handle basic vehicle business where they already live and work, not only at a DMV field office. Steve will restore car registration to what it should have been all along: a flat $73 annual fee for every vehicle. He will strip out the value-based vehicle tax, transportation add-ons, local surcharges, and other stacked charges that turn a basic service into a hidden Car Tax. Registration should cover the cost of administering registrations. It should not be used as a revenue source. Qualified public and private service centers will also be able to handle driver's-license and identification-card transactions, including testing, when they meet state and federal standards. The driver's license or vehicle title will still be state-issued. The difference is that people will no longer have only one government office to rely on. The ordinary registration option must be available for the flat $73 fee. Californians should not have to pay extra just to avoid a DMV line. Local centers may offer clearly labeled premium services, such as after-hours appointments, but the ordinary option must remain affordable. No field office will close until people in that area have an equal or better in-person option. Rural communities will have mobile service where a permanent location is not practical. 3. KEEP THE SYSTEM SECURE AND HOLD PROVIDERS ACCOUNTABLE Every county office and certified service center will connect to one secure state system, use the same identity-verification rules, and follow the same recordkeeping standards. California will continue to meet REAL ID requirements and commercial-driver rules. As separately announced, CDLs will no longer be issued to foreign nationals who don’t speak English. Any organization trusted with a public function must earn that trust. Service centers will face strict requirements for training, background checks, data security, accessibility, record accuracy, and customer service. The state will conduct random audits, investigate fraud, publish performance results, and revoke certification from providers that cut corners or treat people badly. The public should never be trapped with poor service because one government office has a monopoly. 4. TURN UNNEEDED DMV OFFICES INTO OPPORTUNITY Steve will publish an inventory of every DMV lease and state-owned property. Unneeded leases will not be renewed. For suitable state-owned sites, local community colleges, registered apprenticeship programs, and employer partnerships will get the first opportunity to turn former DMV offices into after-school clubs that serve as skills and job-training centers. The focus will be on training that leads directly to work in each community: construction trades, electrical work, HVAC, welding, health-care support, logistics, commercial driving, water and energy infrastructure, and advanced manufacturing. A local operator must be responsible for the program and report real results, including completion, job placement, and wage gains. If there is no practical public use and no credible local training partner, the property should be sold. 5. CUT COSTS AND KEEP REGISTRATION AT $73 California spends $1.46 billion a year on the DMV. That is too much money tied up in an outdated department that gives people a bad experience. Ending unnecessary leases, shrinking the state back office, eliminating redundant overhead, and using competitively selected local service centers will reduce the cost of providing driver and vehicle services. Every contract will be measured against the current cost per transaction. If a provider cannot deliver better service at a lower cost, it will lose the contract. The new state operation will publish its full operating cost, average cost per transaction, and annual savings. Net savings will go first to keeping vehicle costs down, including the $73 flat registration fee. The $73 fee will be exactly that: a fee, not the starting point for another stack of taxes and add-ons. If this reform does not save money and lower what people pay, it is not a reform. Capping vehicle registration at $73 per vehicle per year will reduce revenue from about $11 billion to $2.7 billion. Spending will be reduced proportionately as part of Operation Zero Waste. One essential change: getting better value for money for spending on roads. It is estimated that it costs four times as much to build the exact equivalent section of road in California compared to other states, like Texas - that actually rank higher than California on road quality. CONCLUSION California does not need a better DMV line. It needs no DMV line. Steve Hilton's plan keeps the records secure, keeps safety rules in place, puts registration back to a flat $73, and gets rid of the bureaucracy that wastes people's time and money. Californians should be spending their time getting to work, getting home, and getting ahead, not waiting for the government to let them move on with their day. The DMV is the symbol of California’s bloated, costly and counter-productive nanny state bureaucracy that treats citizens and taxpayers with contempt. The vast majority of states do not have a stand-alone DMV. It is time to put California’s DMV out of its misery. ← Back to all policies

---
snapshot_id: 5c44ef48-776a-5893-9e4e-8ebc61a84251
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee

Saved from https://stevehiltonforgovernor.com/policies/working-class-healthcare-guarantee (rendered page text, built-in browser, 2026-10-07) POLICY THE WORKING CLASS HEALTHCARE GUARANTEE ← POLICY ARCHIVE THE WORKING CLASS HEALTHCARE GUARANTEE Reducing Costs to Make Healthcare Available and Affordable for Working Families in California California politicians boast about how many people have an insurance card. That misses the point. The real test is whether people can see a doctor and afford the bill. Most Californians under 65 get insurance in one of three ways. More than half get it through an employer. More than one-third of Californians rely on Medi-Cal. A much smaller number buy coverage through Covered California or directly from an insurer. Each part of the system works differently, but all three are dragged down by the same problem: California has never seriously confronted the underlying cost of healthcare. Workers pay through payroll deductions, deductibles and lower wages. Medi-Cal patients may pay little or nothing in premiums but struggle to find a doctor. People buying insurance themselves face California's high healthcare costs directly. Steve Hilton will take on the cost of healthcare itself. That means exposing prices, bringing in more providers, cutting out middlemen, stopping fraud and giving patients control over the money spent in their name. That way Steve can deliver the most important missing piece of the healthcare system in California today: a Working Class Healthcare Guarantee - healthcare that is available to working families in California for an affordable premium and with a low deductible that doesn't make a mockery of the whole idea of health insurance. THE PROBLEM Healthcare in California is too expensive and too hard to get. Patients rarely know what a service will cost before receiving it. State rules limit who can provide care and make it harder to open clinics or expand hospitals. Pharmacy benefit managers and other middlemen make money from deals patients never see. The result is predictable. Prices rise. Insurance premiums rise with them. Patients pay more while doctors and independent providers spend more time fighting through bureaucracy. California politicians respond by spending more government money and enrolling more people in government programs. Then they declare success. But more spending is not success if families still cannot afford care, and an insurance card is not much use if nobody will take it. HOW CALIFORNIA GOT HERE Insurance was supposed to protect people from large and unexpected medical bills. It has become a complicated payment system for almost every medical service. Patients do not see the real price, and providers have little reason to compete directly for their business. California made matters worse by piling on mandates, licensing restrictions and approval processes. The biggest institutions learned how to work the system. Smaller providers and patients were left to pay for it. Steve's plan starts from a simple principle: the system should work for the patient, not the people who control the paperwork. THE PLAN 1. CUT THE COST OF EMPLOYER HEALTHCARE Employer coverage is not free. In 2025, the average California employer plan cost more than $10,000 for one person and more than $28,000 for a family. Workers may not see the whole bill, but they pay it through contributions, deductibles and wages swallowed up by rising healthcare costs. Bringing those costs down starts with prices. Hospitals, physician offices, outpatient centers and pharmacies will have to show patients real dollar prices before nonemergency care. California already collects huge amounts of payment data, but much of it is buried in files almost nobody can use. A price hidden in a computer file is not transparency. Steve will put the information on one website where patients and employers can make real comparisons. Prescription drugs are another obvious place to act. California has recently passed restrictions on pharmacy benefit managers, including a ban on spread pricing in new and renewed contracts. Those rules will be enforced and the remaining loopholes closed. The state will publish cash and Health Savings Account prices for the 100 most commonly used generic medicines. Patients will be allowed to pay the lower cash price when it beats the insured price, and unnecessary barriers to lawful mail-order and out-of-state pharmacy competition will go. California also needs more people providing care. Some qualified nurse practitioners can now work independently, but the remaining restrictions are excessive. Steve will finish that reform, give qualified physician assistants greater authority and bring California into the Interstate Medical Licensure Compact so experienced doctors can start practicing here without an unnecessarily slow licensing process. The same approach applies to clinics and hospitals. California already has a 30-day approval process for a narrow group of clinics affiliated with experienced nonprofit operators. Steve will make rapid approval available to any qualified neighborhood clinic that meets clear health and safety requirements. Hospital projects will face firm review deadlines. Limited extensions to California's 2030 seismic deadline already exist, but too many hospitals remain at risk of closing because they cannot meet an arbitrary timetable. Steve will expand the extension process and allow practical plans that protect earthquake safety without taking hospital beds out of a community. California should produce more of its own medicine too. Pharmaceutical enterprise zones in the Central Valley and Inland Empire will offer tax and regulatory relief to companies that actually manufacture essential and generic medicines here. No production and no California jobs means no incentive. These changes attack the costs that drive up employer premiums in the first place. That is how workers keep more of what they earn. 2. REPLACE BUREAUCRATIC MEDI-CAL WITH PATIENT CONTROL Medi-Cal functions as a separate, second-class system: fewer than half of doctors who have signed Medi-Cal contracts accept Medi-Cal patients, reimbursement runs at barely half of Medicare rates, and peer-reviewed outcomes data show Medicaid patients faring worse than comparably situated privately insured patients. California already spends more per Medi-Cal enrollee than the average cost of private insurance per enrollee, yet delivers worse access and outcomes. The problem is the structure of the benefit, not the level of spending. Medi-Cal spends thousands of dollars in a patient's name, but the patient controls almost none of it. Government agencies and managed-care organizations decide where the money goes. The patient gets a card and may still be unable to find a doctor. Fraud drains even more money away from legitimate care. California already has anti-fraud operations inside the Department of Health Care Services and the Attorney General's office, but responsibility is divided. Steve will put them into one California Health Program Integrity command working directly with federal investigators. Modern claims analysis can catch impermissible billing, duplicate identities and excluded providers before payment. Honest mistakes can be corrected. Deliberate theft will mean removal from the program, prosecution and repayment. The larger reform is to give patients control. For working-age adults who are not seniors or disabled, California will seek federal approval for personal healthcare accounts containing approximately $8,000 to $10,000 a year. Preventive care and protection against catastrophic medical costs will remain covered. Patients will use their accounts for qualified healthcare expenses and choose their own providers. Money left over will remain available for future care instead of disappearing at the end of the year. Doctors and clinics will have to compete for the patient rather than the patient begging a bureaucracy for permission. California will pursue a federal Section 1115 demonstration and begin in a region willing to participate. If it works, it can expand. Federal law already requires work or community engagement from many able-bodied Medicaid adults beginning in 2027. California should implement that requirement. Medi-Cal must protect children, seniors, people with disabilities and families going through hard times. It should not become a permanent destination for adults who are able to work. 3. GIVE PEOPLE BUYING THEIR OWN INSURANCE A REAL ALTERNATIVE The individual market covers a much smaller share of Californians, but the people in it feel every increase directly. They include self-employed workers, independent contractors, small-business owners and people who retire before becoming eligible for Medicare. They need a lower-cost alternative focused on what insurance is supposed to do: protect against major medical expenses without making ordinary care unaffordable. Steve's Working Class Healthcare Guarantee will give them access to coverage with an affordable premium and a low deductible. Californians who prefer high-deductible coverage paired with a larger and more flexible Health Savings Account will still have that option. To bring down premiums, Steve will apply for a Section 1332 State Innovation Waiver under the Affordable Care Act. Section 1332 allows a state to redesign its individual insurance market if the new system provides coverage that is at least as comprehensive and affordable, covers a comparable number of people and does not increase the federal deficit. California will use the waiver to establish a reinsurance program. Reinsurance pays part of the small number of exceptionally high medical claims so those costs do not drive up premiums for everybody else. When premiums fall, the federal government spends less on premium tax credits. Section 1332 allows those federal savings to return to California as pass-through funding to help pay for the program. Alaska used this approach through the Alaska Reinsurance Program, which covers claims tied to 34 high-cost medical conditions. Federal officials estimate that premiums are 38.5 percent lower than they would have been without the waiver. Reinsurance directly lowers the premium. California will combine it with existing state assistance and savings from the cost reforms throughout this plan to bring down the deductible too. Covered California's Bronze plans now work with HSAs, but California still refuses to recognize the full federal tax benefits of the accounts. Steve will end that state tax penalty. Qualifying plans will also be able to provide a $500 annual wellness contribution when participants complete eligible preventive care or healthy-lifestyle activities. The same Section 1332 waiver will seek approval for simpler coverage options that protect against major medical expenses without forcing Californians to pay for a long list of mandates they do not want. Californians buying their own coverage should have real choices, including a plan that delivers the affordable premium and low deductible promised by the Working Class Healthcare Guarantee. A BETTER WAY FORWARD California does not lack healthcare spending. It lacks a system that treats the patient as the customer. The current system answers to government agencies, insurers, hospital bureaucracies and middlemen. Steve will make it answer to the patient, and focus on delivering a new Working Class Healthcare Guarantee, with affordable premiums and low deductibles for working families. ← Back to all policies