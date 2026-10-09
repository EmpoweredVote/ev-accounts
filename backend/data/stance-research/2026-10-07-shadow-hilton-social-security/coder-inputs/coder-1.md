You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-social-security/labels/coder-1.json. Write JSON only, matching
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

### topic_key: social-security
topic_id: 87d20824-a6e9-407b-983c-65440084a0ab  served_revision_id: 8defc029-0b7e-426f-b838-a2e170f566c9
Question: How should Social Security be funded and structured for the future?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.
  2. increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.
  3. make small adjustments to both benefits and taxes to keep Social Security stable for future generations.
  4. gradually reduce future benefits rather than raise taxes to keep Social Security solvent.
  5. transition Social Security to private investment accounts that individuals control themselves.

#### Annex

# social-security — served revision 8defc029-0b7e-426f-b838-a2e170f566c9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Social Security be funded and structured for the future?"

**Orientation:** standard. Rung 1 is the largest public programme (bigger benefits, more tax), rung 5
replaces it with private accounts. The rungs order **benefit level and how it is paid for**. Rungs
1–4 each pair a benefit side with a tax side, so most of them are compound.

**Levels with a lever:** federal. Only Congress sets benefits and the payroll
tax. State and local officeholders hold no lever on any rung.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "OASDI", "trust fund", "solvency", "payroll tax", "FICA", "taxable maximum" or "wage
base cap", "donut hole", "full retirement age", "COLA", "CPI-E", "chained CPI", "progressive price
indexing", "minimum benefit", "WEP" and "GPO" (Windfall Elimination Provision, Government Pension
Offset), "personal accounts", "carve-out accounts", "fiscal commission".

1. **"expand Social Security benefits significantly and remove the income cap on payroll taxes to
   fund it."**
   - Means: benefits rise a lot for beneficiaries in general, paid for by taxing all earnings.
   - Operative clauses: [a] a significant benefit increase; [b] remove the payroll-tax cap; [c] the
     tax pays for the increase. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: authoring or co-sponsoring a single-subject bill that raises
     benefits broadly (an across-the-board increase, a higher COLA formula) **and** applies the
     payroll tax to earnings above the present cap.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A "donut hole" design (tax again above a threshold, with a gap below it) meets [b] "remove the
     income cap": no upper limit remains. The **size of the benefit increase** then separates rung 1
     from rung 2 _(ruled 2026-10-01)_.
   - Commonly confused with rung 2 because both raise taxes on higher earners. When the tax side does
     not separate them, the **size** of the benefit increase does: across-the-board → rung 1
     territory; one group or a small amount → rung 2 territory _(proposed)_.

2. **"increase Social Security benefits modestly while raising taxes on higher earners to strengthen
   the program."**
   - Means: a small benefit increase, paid for by more tax on high earners.
   - Operative clauses: [a] a modest benefit increase; [b] raise taxes on higher earners. Compound:
     one side only → `compound-partial`.
   - Establishing evidence looks like: a bill or own words with both a limited increase (a minimum
     benefit, a targeted increase) and a tax rise aimed at high earners.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - **[real] (codebook V6, H5).** Co-sponsoring the Social Security Fairness Act (WEP/GPO repeal, a
     benefit increase for one group, no tax side) plus "must be willing to reform" → BLANK
     `compound-partial`.

3. **"make small adjustments to both benefits and taxes to keep Social Security stable for future
   generations."**
   - Means: small changes on both sides, without a large cut or a large tax rise.
   - Operative clauses: [a] a small benefit adjustment; [b] a small tax adjustment. Compound (V4.2
     names this rung): one side only → `compound-partial`.
   - Establishing evidence looks like: a solvency bill or own words that name a change on each side
     (a small retirement-age or COLA change **and** a small payroll-tax or wage-base change).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a benefit-side change (raise the retirement age) is in
     both. Rung 3 needs a tax side; rung 4 needs the tax side **rejected**. A benefit change plus
     openness to a tax change → rung 3 territory; a benefit change alone → `compound-partial` for
     both _(proposed)_.

4. **"gradually reduce future benefits rather than raise taxes to keep Social Security solvent."**
   - Means: future benefits grow less or are cut over time, and taxes are not raised.
   - Operative clauses: [a] gradually reduce future benefits (a higher retirement age, chained CPI,
     price indexing, means-testing all count); [b] **rather than** raise taxes — the person rejects a
     tax rise for solvency. [b] must be stated (V4.2 "Silence is not a clause"). Compound: [a] only →
     `compound-partial`.
   - Establishing evidence looks like: a benefit-side solvency plan **plus** the person's own words or
     record against a tax rise.
   - A signed no-new-taxes pledge is `statement-answer` (codebook V3, H8) and can meet [b], in cycle
     (V5) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - S1 rung 4 was "raise the retirement age **and** reduce benefits for higher earners". The served
     rung adds [b] and drops the named mechanisms. S1 evidence on the retirement age alone now meets
     [a] only.
   - **[real] (codebook V6, H5).** A voter-guide answer for "gradually raising the retirement age" and
     a later "everything's on the table" (`rhetorical`) → [a] only, [b] unmet → BLANK
     `compound-partial`.

5. **"transition Social Security to private investment accounts that individuals control
   themselves."**
   - Means: the programme moves to accounts that each person owns and invests.
   - Operative clauses: [a] a transition of the programme to private accounts; [b] individual control.
   - Establishing evidence looks like: a bill or own words that move payroll-tax contributions into
     individually owned investment accounts in place of the benefit.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A voluntary carve-out of a small part of the payroll tax is a step, not a transition →
     `direction-only` _(proposed)_. Accounts **added** on top of Social Security (funded outside the
     payroll tax) → `adjacent` _(proposed)_.

**Hard cases:**
- **"Protect Social Security", "no cuts", "keep our promise"** exclude rungs 4 and 5 only →
  `direction-only`.
- **A fiscal or trust-fund commission bill** orders a report → V4 `study-directive`.
- **Income tax on benefits** (exempt benefits from income tax, a senior deduction) is not the payroll
  tax and not a benefit level → `adjacent` _(proposed)_.
- **Budget resolutions** that assume Social Security changes → V4 `multi-subject` _(proposed)_.
- **SSA administration** (field offices, staffing, phone wait times) → `adjacent`.
- **Ratings from seniors' groups** → V3 `not-evidence`; follow them to the roll calls.


## Sources

---
snapshot_id: 572948ee-3fee-57e2-b63b-8a4f83a2700b
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/abolish-the-dmv

Saved from https://stevehiltonforgovernor.com/policies/abolish-the-dmv (rendered page text, built-in browser, 2026-10-07) POLICY ABOLISH THE DMV ← POLICY ARCHIVE ABOLISH THE DMV A CALIFORDABLE Plan to Cut Vehicle Registration to $73, End DMV Lines, Eliminate Bureaucracy, and Turn Empty Offices Into Opportunity OVERVIEW California is a car state. For most people, a car is how they get to work, get their kids to school, run a business, and live their lives. Yet something as basic as renewing a registration can still mean taking time off work to deal with the hated DMV. California spends $1.46 billion a year on a department with 170 field offices. It is a huge, old-fashioned monopoly that treats the taxpayers who fund it with complete contempt. It is the miserable symbol of California's bloated, costly nanny state bureaucracy, bossing people around while charging a fortune for the privilege. The DMV has trained people to expect delays, confusing paperwork, and bad service. Most states do not have a stand-alone DMV - California is one of only ten or so states with a separate DMV bureaucracy. Of course it is important that the state has secure records, legitimate licenses, and strong fraud prevention. It does not need to make people stand in line all day to receive rude, surly - and insanely slow - service for things that in other countries and states are handled entirely online. Steve Hilton will abolish the DMV, set annual vehicle registration at a flat $73, and give Californians better, cheaper options. THE PROBLEM The DMV is built around the bureaucracy, not the public. If a transaction cannot be completed online, Californians have to fit it into the state's schedule. They take time off work, arrange child care, miss appointments, and hope the person behind the counter can solve the problem that day. If the service is slow, confusing, or unhelpful, there is nowhere else to go. The DMV has a monopoly. For years, Democrats have tried to patch this failure with another website, another kiosk, another appointment system, or a new set of office hours. None of that fixes the basic problem. The public is still expected to work around the government instead of the government working around the public. And California’s basic $73 vehicle registration fee is buried under a value-based vehicle tax, transportation add-ons, and local surcharges. Drivers can end up paying $500, $600…even $1,000 or more, while in most other states, registration is under $100. California already uses kiosks and private partners for some transactions, but the better option can come with an additional fee. People who can afford it sometimes buy their way out of the line. Everyone else is stuck. Other states have shown a better way. Colorado routes most title and registration work through county offices. Arizona allows regulated local providers to handle registrations, titles, driver's licenses, and road tests. California can do the same while keeping the state in charge of security and standards. STEVE HILTON'S PLAN: ABOLISH THE DMV The point is simple: get rid of the DMV bureaucracy and buildings, not the services people need. Steve Hilton's plan keeps the state responsible for secure records and safety, but gives Californians more convenient and affordable ways to get things done. 1. ABOLISH THE DMV AS A STAND-ALONE DEPARTMENT Steve will order a full audit of every DMV function, office, lease, contract, and cost. It will report within three months. He will then send the Legislature a No More DMV Act to eliminate the Department of Motor Vehicles. The state will keep a lean records and safety operation within existing government. Its job will be to maintain the statewide database, issue state credentials, protect personal information, investigate fraud, and enforce safety rules. It will not run a giant network of public waiting rooms. The goal is a much smaller state back-end that does the work only government must do. 2. MAKE DMV SERVICES LOCAL AND CUT REGISTRATION TO $73 Routine title, registration, plate, and renewal transactions will move to county offices and certified local service centers. Californians should be able to handle basic vehicle business where they already live and work, not only at a DMV field office. Steve will restore car registration to what it should have been all along: a flat $73 annual fee for every vehicle. He will strip out the value-based vehicle tax, transportation add-ons, local surcharges, and other stacked charges that turn a basic service into a hidden Car Tax. Registration should cover the cost of administering registrations. It should not be used as a revenue source. Qualified public and private service centers will also be able to handle driver's-license and identification-card transactions, including testing, when they meet state and federal standards. The driver's license or vehicle title will still be state-issued. The difference is that people will no longer have only one government office to rely on. The ordinary registration option must be available for the flat $73 fee. Californians should not have to pay extra just to avoid a DMV line. Local centers may offer clearly labeled premium services, such as after-hours appointments, but the ordinary option must remain affordable. No field office will close until people in that area have an equal or better in-person option. Rural communities will have mobile service where a permanent location is not practical. 3. KEEP THE SYSTEM SECURE AND HOLD PROVIDERS ACCOUNTABLE Every county office and certified service center will connect to one secure state system, use the same identity-verification rules, and follow the same recordkeeping standards. California will continue to meet REAL ID requirements and commercial-driver rules. As separately announced, CDLs will no longer be issued to foreign nationals who don’t speak English. Any organization trusted with a public function must earn that trust. Service centers will face strict requirements for training, background checks, data security, accessibility, record accuracy, and customer service. The state will conduct random audits, investigate fraud, publish performance results, and revoke certification from providers that cut corners or treat people badly. The public should never be trapped with poor service because one government office has a monopoly. 4. TURN UNNEEDED DMV OFFICES INTO OPPORTUNITY Steve will publish an inventory of every DMV lease and state-owned property. Unneeded leases will not be renewed. For suitable state-owned sites, local community colleges, registered apprenticeship programs, and employer partnerships will get the first opportunity to turn former DMV offices into after-school clubs that serve as skills and job-training centers. The focus will be on training that leads directly to work in each community: construction trades, electrical work, HVAC, welding, health-care support, logistics, commercial driving, water and energy infrastructure, and advanced manufacturing. A local operator must be responsible for the program and report real results, including completion, job placement, and wage gains. If there is no practical public use and no credible local training partner, the property should be sold. 5. CUT COSTS AND KEEP REGISTRATION AT $73 California spends $1.46 billion a year on the DMV. That is too much money tied up in an outdated department that gives people a bad experience. Ending unnecessary leases, shrinking the state back office, eliminating redundant overhead, and using competitively selected local service centers will reduce the cost of providing driver and vehicle services. Every contract will be measured against the current cost per transaction. If a provider cannot deliver better service at a lower cost, it will lose the contract. The new state operation will publish its full operating cost, average cost per transaction, and annual savings. Net savings will go first to keeping vehicle costs down, including the $73 flat registration fee. The $73 fee will be exactly that: a fee, not the starting point for another stack of taxes and add-ons. If this reform does not save money and lower what people pay, it is not a reform. Capping vehicle registration at $73 per vehicle per year will reduce revenue from about $11 billion to $2.7 billion. Spending will be reduced proportionately as part of Operation Zero Waste. One essential change: getting better value for money for spending on roads. It is estimated that it costs four times as much to build the exact equivalent section of road in California compared to other states, like Texas - that actually rank higher than California on road quality. CONCLUSION California does not need a better DMV line. It needs no DMV line. Steve Hilton's plan keeps the records secure, keeps safety rules in place, puts registration back to a flat $73, and gets rid of the bureaucracy that wastes people's time and money. Californians should be spending their time getting to work, getting home, and getting ahead, not waiting for the government to let them move on with their day. The DMV is the symbol of California’s bloated, costly and counter-productive nanny state bureaucracy that treats citizens and taxpayers with contempt. The vast majority of states do not have a stand-alone DMV. It is time to put California’s DMV out of its misery. ← Back to all policies

---
snapshot_id: 82576ce4-a2f4-5914-9b86-465b48159485
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: 514b92af-d477-5fb0-81af-bed0ff3aed28
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan

Saved from https://stevehiltonforgovernor.com/policies/emergency-election-count-accelerator-plan (rendered page text, built-in browser, 2026-10-07) POLICY EMERGENCY ELECTION COUNT ACCELERATOR PLAN ← POLICY ARCHIVE EMERGENCY ELECTION COUNT ACCELERATOR PLAN INTRODUCTION California should be able to conduct elections that are both secure and timely. Every legal ballot should be counted, but voters should not have to wait weeks to find out the outcome of an election. The state routinely mobilizes personnel and resources during emergencies. When election offices face massive post-election backlogs, California should do the same. By temporarily assigning qualified state employees, deploying rapid-response support teams, and funding expanded county operations, California can accelerate ballot processing, reduce delays, and provide voters with election results more quickly while maintaining the integrity and security of the process. California is the fourth largest economy in the world, and home of the technology industry that has so dramatically changed the world. When it comes to elections, it’s time we acted like it. Ultimately, California needs broader reforms to its election system. But in the short term, for the primary election of June 2nd 2026, we cannot continue with a process that leaves millions of voters waiting weeks for results. Governor Newsom should immediately issue an emergency Executive Order designed to bring ballot-processing backlogs to a close as quickly as possible, with the goal of guaranteeing complete and verified election results within 48 hours of the deadline for receiving mail-in ballots: final election results by 8pm on Thursday 11th June. If India can count over 600 million ballots in 24 hours, surely California can count a tiny fraction of that number in twice the time. A SYSTEM THAT ISN’T WORKING California’s election delays are not an isolated problem. They are yet another symptom of a government that has stopped delivering basic results. Californians have been promised a high-speed rail project that has barely begun after years of delays and billions of dollars in spending. State and local governments have spent billions addressing homelessness while encampments remain a visible crisis in communities across the state. Now California once again finds itself waiting weeks for election results after fewer than ten million ballots were cast. It is an extraordinary and unacceptable shambles. California has become a global laughing stock for its inability to conduct elections in an efficient, timely manner. Californians have been conditioned to accept delays that would be unacceptable in almost any other area of government. Elections should be secure, accurate, and timely. The fact that voters can wait weeks for final results is evidence that the system is not functioning as it should. This is not about counting fewer ballots or lowering standards. It is about basic governing competence, which has completely collapsed in California, it now seems. Voters deserve an election system that is both accurate and efficient. PLAN FOR CHANGE California’s election laws should be reformed to deliver faster, more transparent, and more trustworthy election results. The following reforms would dramatically accelerate election results while preserving election integrity: Require vote-by-mail ballots to be received by Election Day rather than accepted for several days afterward if postmarked by Election Day. Mail ballots only to voters who specifically request them rather than automatically sending ballots to every registered voter. Provide free voter identification cards to all registered voters and require identification for in-person voting. Expand pre-election ballot processing so counties can verify signatures, prepare ballots for tabulation, and complete administrative review before Election Day. None of these reforms would eliminate the need to count every legal ballot. But together they would dramatically reduce post-election delays, improve transparency, strengthen confidence in the process, and move California toward a system where voters know the outcome of elections in hours, not weeks. EMERGENCY ELECTION COUNT ACCELERATOR CORPS While broader reforms are implemented, Governor Newsom should act immediately to accelerate the count in the primary election of June 2026. The Governor should establish an Emergency Election Count Accelerator Corps by temporarily deploying available state employees from non-essential administrative positions to county election offices experiencing significant ballot-processing backlogs. These personnel would work under the supervision of county Registrars of Voters and assist with ballot processing, administrative review, data entry, ballot preparation, and other support functions permitted under existing law. The state should also create regional election surge teams that can be rapidly deployed to counties facing the largest backlogs, ensuring staffing resources are directed where they are needed most. In addition, California should establish an Election Count Accelerator Fund to reimburse counties for overtime, expanded shifts, weekend operations, and other temporary costs associated with accelerating ballot processing after Election Day. The proposal would not change election laws, security procedures, or vote-counting standards. Every ballot would still be processed according to existing law and under the authority of local election officials. The goal is simple : count every legal ballot , maintain election integrity , and deliver timely results that voters can trust . Specifically , ensure that in the primary election of June 2026, Californians have complete and verified results within 48 hours of the deadline for receiving mail – in ballots . Final election results by 8 pm on Thursday 11 th June . ← Back to all policies

---
snapshot_id: 85e488b9-39de-5e70-8005-1ec15092da6e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## news_clip — CA CA-Courier-SteveHiltonInterview - OTR page: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7 - Video: https://www.youtube.com/watch?v=VIZ1h4OaImU - Date on On the Record: 2026-04-01 - Kind: news_clip · CA-Courier-SteveHiltonInterview · CA - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:04] to be with you. [0:33] Well, the first thing we've got to say is why we need to cut taxes in California because we have an insane level of taxation. We have the highest taxes in the country for the worst results and one of the consequences of that is that we have on all these measures the worst performance of any state. It's really shocking. Right now we have the highest poverty rate in the country tied with Louisiana. We have the highest unemployment rate of all 50 states. We have the highest cost of living. We have the worst business climate according to Chief Executive Magazine for the last 10 years. So businesses are leaving, investment is going, jobs aren't being created. That's why we have high unemployment and high poverty. So a huge part of that is the tax burden and we've got to reduce it and that means you have to reduce spending. So that's the starting point. When you look at who's really suffering as a result of all these things, not just the taxes but the high cost of gas and housing, groceries, all of these the most expensive in the country. Electric bills, the second highest after Hawaii, insurance, all these unbelievable burdens. Working class Californians are hurting the most. Regular working people who work incredibly hard and everything's so expensive and then they're taxed for it. And so the first, I mean in many counties, the official poverty level [1:52] is now $100 ,000. So in many other states, you look at $100 ,000 and think that's a decent income. In California, it doesn't get you very far. So the last thing we should be doing is taxing those people. That's why I wanted to start with that. $100 ,000 to raise the threshold for paying state income tax. That would help millions of Californians, thousands of dollars extra in their budgets every year. That one, I think that we can, I think there's a very real prospect of getting out through the legislature because one thing I've noticed is that my tax plan, that part of it has actually been copied. By some of the other Democrat candidates, including Katie Porter. So I think that actually we can get support for that part of it. That's the pro -worker part. The second part, which is a flat tax above $100 ,000, 7 .5%. Now that is going to be much harder to implement. Partly because a lot of these taxes are not just too high, they're too complicated. We've got endless different tax bans that make it really fiddly and annoying and bureaucratic to do your taxes. And it's a real disincentive to start businesses here. I'm a business owner. Most of my career has been in business. And it's just a nightmare. And the taxes are a big part of it. Now, some of those tax rates that we have have been established by ballot initiative over the years. That's one of the reasons we have this complicated system. So it won't be easy to undo that. But I think we've just got to make the argument. And so my attitude to all of this is your starting point is see what you can get done through the legislature. Then see what you can get done through executive action, through the administrative agencies. And then if none of that works, then for these really major reforms, we probably will have to go to a ballot initiative at some point in the future, after I'm elected and take office in January. [3:53] to. I mean, that's how it works. That's how our system works. So I've got a very strong focus. You know, when I'm the general election candidate, I'm very clear that my responsibility as the top of the ticket in California is to help elect Republicans everywhere. It's not just about my race. It's about the other statewide races. I'm the first candidate ever from either party that's put together a team to run for the other statewide offices. We can get to that a little bit later. But in terms of the legislature, it's going to be a huge priority for me to try and help elect more Republicans this cycle in the assembly and the Senate because then we do have a chance to break the supermajority this year. It's not going to be easy, but it's not impossible. So even if we get rid of the supermajority in one of the two chambers, that's already really helpful because then they won't be able to just block everything. And so you start to create some opportunity there. I think also the truth is that [4:51] when I'm elected this year, nobody expects a Republican to win in terms of the Democrat. They're so arrogant. It's 16 years of one party rule. They think it's going to go on forever. But actually, I think we've got a very good shot this year. When I'm elected, that's going to be a political revolution in California. And I think when I take office in Sacramento in January, it really will change the dynamic. I really believe that. It's hard to imagine it right now, but it's going to be a shock to these Democrats that they've got a Republican governor. And I think we will be able to do that, to work with them. And there's a couple of things I'd add. Number one, I've got experience of doing that. So most of my career, as I said, I've been in business, working around the world, but also starting my own companies, including restaurants, a whole range of different businesses. But I have had a few years working in government at a very high level. I was senior advisor to the prime minister in the UK. I worked in 10 Downing Street. I had a little office there next to the cabinet room and worked to try and make things happen. In a coalition government. So my boss was David Cameron, the conservative prime minister, but it was a coalition with another party, the Liberal Democrat Party. And I shared an office with my opposite number in the other party, Polly McKenzie. We used to argue a lot, but we also worked together to find the areas where we could make change happen. So I've got experience of doing that. It's not easy. And of course, you're not going to get everything done that way, but it's not true to say nothing can happen. And I think that it really will [6:17] change things to have a Republican governor. I think the whole mood in Sacramento will change. A lot of things that are seen as impossible will suddenly start to become more realistic. The other thing I'd point to now talking about the team I've put together to run with me for the other statewide offices, including for lieutenant governor. [6:34] And that's the concept of a ticket has never been done before in California, statewide races. But I think we've got to try new things and do things differently. Gloria Romero, who's running with me for lieutenant governor, she was previously the Democrat leader in the state Senate. So that was many years ago. And she left the party. She used to work across the aisle, but then the party went very left -wing. I met her when she was working with Rick Grinnell on a ballot initiative for school choice. It was Rick who introduced me to Gloria. And she's now a Republican, fully signed up. She's endorsed President Trump, spoke at the Coachella rally. But she still has relationships there. As the lieutenant governor, you're the president of the Senate. And so you have a big role to play. She understands how that system and the process work in the legislature. And so I'm running, I'm obviously an outsider. I've never run for office before. And I'm going there as an outsider to take on all the nonsense in Sacramento. But I think it's gonna be helpful to have by my side someone who has been there and knows how it works and has relationships in the Democrats. I mean, I went there with Gloria. We were launching some policy thing and went into the state Capitol. And it's a long time since she's been there and she's a Republican now. But they invited her onto the Senate floor as a mark of respect. She was previously the leader. I watched it from the gallery. They all stood and cheered. [8:01] Democrats, because there's relationships there. And so I think that it seems very out of reach, the idea that we could actually have something positive happen. But I don't know, I've got a very strong feeling that in these various ways, we really can get some things done. [8:49] Well, the first business I started was 1997, a company called Good Business. And we were a consulting firm. We worked with some of the biggest companies in the world. Then about two years later, we launched, with my business partner, we launched a couple of restaurants in the UK called The Good Cook, which is kind of an offshoot of our consulting business, but it was two real restaurants in London. And they were, that's a really tough business, to be honest. You learn a lot from it, but in some ways we did well, in other ways it was tough. It's very difficult to make money in that business. Then I went back into politics and government, worked in 10 Downing Street for a while. We moved here in 2012 with my wife and my two sons. And for the first couple of years I was here, I talked at Stanford, but then I launched another business here, a tech company, a tech platform called CrowdPak. And that was a crowdfunding platform for politics and candidates and political causes. And so that's an equivalent, you could think of it as a GoFundMe for political candidates and so on. And so that was a business that started, I think, well, I got going 2013, probably launched 2014. Ran that for a few years before being invited to host a show on [10:07] Fox News. And then after that, the final business that I started was a media company, really to produce podcasts and so on. That was CR Productions. So there's been the four in total. So that's that. I don't know what he's talking about with this fast track thing. It's completely ridiculous. We, you know, it wasn't that fast. We moved here in 2012 [10:32] on a visa that [10:34] then got applied for a green card and got that and got my citizenship in 2021, nine years. So I actually genuinely don't understand what that's about. Do you have any more specifics on what the allegation is? [10:52] years? Yes. Is that fast? [11:01] I literally think that is a completely made up, ridiculous smear, which I don't even understand. I don't understand why someone would question the process there when it's just an independent, bureaucratic process. They're saying that everyone has to go through. [11:18] It's really ridiculous. [11:23] So what specifically, that I don't understand. Again, what was the specific thing there? [11:36] Well, partly we've just been discussing how important it's gonna be to be able to work with Democrats in order to make change happen. But actually, I think what's being referred to there is one of my businesses, CrowdPak, which is a crowdfunding platform [11:52] for politics and candidates and so on. And it was an open platform. So like GoFundMe, or like X. So I think what he's getting at there is that Democrats used my business to raise money, as did Republicans, as did anyone who wanted to. So it's a little bit like criticizing Elon Musk for things that Democrats say on X. It's an open platform. Yeah, people can use it. [12:38] Well, again, I think we have to be practical. I've always been really clear that I never wanna say something that can't be delivered just to make people feel good about whatever the issue may be. I always wanna be realistic about what you can do. And on this particular issue, which is so deeply felt and is so personal for so many people, I think there's just a couple of things I'd say. First of all, I do think that it's right that the issue was now, for so many years, it was in the hands of judges and the people felt they didn't have a say. And thanks to President Trump's Supreme Court appointments and where that led, it now has been put back in the hands of the people through their representatives, because states have been able to make their own determinations on that issue. And you've seen a wide range of policies implemented across America. And I totally support that approach, because the idea that you've got one size fits all on something that's so personal and people have such strong views about was always one of the real problems with this issue. People felt that their voices weren't heard. Now, in the end, you've gotta decide what level this is regulated. It has to be regulated at some level. Previously it was the national level, now it's at the state level. And so in different states, they voted for different things. Here in California, in 2022, it was on the ballot [13:57] to be enshrined in the state constitution, the right to abortion. And it was, and it was passed with a two -thirds majority. So that's how it works. That's how the system works. So my attitude to this is what can I get done as governor to move us in this sort of direction of life, towards life, in a way that I can actually deliver. So the first thing I'd say on that is that all the other things that I wanna get done for California to make it, to make our state, as I say, Cal affordable, to make this a place where young people wanna, can see a future where they can start a family here. One of the most heartbreaking things to me is when you talk to young people and they say, well, I can't imagine living in California. It's too expensive. I'll never be able to do it here. I have to move to another state. I want this to be a place where people see the opportunity to start and raise a family and have children and grow their families here in California, something I talked to Charlie Kirk about a lot. He was a good friend of mine and endorsed me on day one. And it was a big thing, big focus for him as well. That ability to, because you hear stories where people say, yeah, I'd love to have more children, but [15:07] it's too expensive or I can't afford, I can only afford a tiny apartment and so I can, et cetera. They've got to change all that. So that's actually part of the story of moving us towards life. More specifically on the issue itself, [15:19] you've got a couple of things. First of all, I think we have to just encourage a culture of responsibility on this. One of the things that I just think is really, I'm gonna use a pretty strong word, it's kind of disgusting actually, is the way that, it's just the way that this issue has evolved, particularly in places like California, is that it's almost as if abortion is now seen as a perfectly acceptable form of birth control, just like any, and I just think that's really, really dark and not where we want to be as a society. So you have to, [15:50] and the governor can, through working with the faith, I've had lots of conversations, for example, with Jack Hibbs, who's a big supporter of mine from Calvary Chapel, Chino Hills, and others in the faith community about how we can work together to encourage more responsibility, a culture of responsibility. So we minimize the number of unwanted pregnancies in the first place. So there's something you can do more actively on that as governor, and I will. Secondly, if you are in that situation, I think it's just outrageous that what you're seeing now from the government in California is actively [16:22] attacking pro -life centers and places that are, I just met someone who runs one of those this morning, encouraging adoption, for example, as an alternative and helping prospective mothers think through that process. That's being discouraged and actually aggressively targeted by the Newsome administration. So that we need to reverse and encourage adoption as an alternative. And then the final piece of it, I just think this whole spending taxpayer money promoting abortion, which is what's happening right now, our money is just not okay, including, [17:02] again, stuff that I just think is really wrong, like what some people have described as abortion tourism, [17:09] where our taxpayer money is being spent on ads in other states, [17:14] saying, come to California, all that's gonna stop. [17:32] Well, again, I don't really understand what he's talking about, because I think what he said something about, the way he framed it was as if what I was saying wasn't true. I've never said anything about him that's not true. Nothing. I mean, the things that I've been pointing out are things that are true about his record, unlike what's been said about me, as we've just discussed, not true at all. And people can watch for themselves. I think what he's getting at is the fact that when he was, as sheriff, during the Black Lives Matter riots in 2020, he took a knee for Black Lives Matter. And he argues that he was praying. I've never said one way or the other. I've just said, and it's clear that he took a knee. That's a physical action, taking a knee. And you can see that. It's documented, there's video, there's photographs. You can watch it, it's on a website, blmbianco .org. So people can see that for themselves. So it's obvious that he took a knee. He challenges the interpretation of that as being something that was done for BLM. And he says he was praying. That's what he says. He said it many times. I've heard him say it many times. Now, people just watch the video and see if that's true. I don't think I've ever said anything about that that's not true. And it's not backed up by documented evidence on the day. The second thing I've pointed out, and maybe he's getting at this, is again, just repeating what he said on an issue that is actually probably the biggest policy area where we really have a disagreement, which is on immigration, where he has said a number of things that I just strongly disagree with. He said that he won't, and his sheriffs in his department, won't work with the federal authorities to enforce immigration law. I disagree with that. The Sanctuary State Law in California allows for cooperation between state and federal law enforcement on immigration. So I don't know why he would not want to do that. But he said that. It's a video, you can watch it. The other part of this that I strongly disagree with is his contention that people who are here, who came across the border during the Biden years, are actually here legally. And his view that, which again, I'm quoting almost word for word now, that it doesn't matter how you came here, the 10 to 11 million people who came under Biden, the illegal immigrants here, we have to give them a pathway to citizenship. I just disagree with that. That's rewarding law breaking. We, as I often point out, we already have a pathway to citizenship. It's called legal immigration. I just took it. And so I just disagree. Now he may not [20:12] like the fact that when this issue comes up, I'm pointing out his past statements, but they're his words. I've never said anything that's not true. [20:26] to be with you. Thank you.

---
snapshot_id: 532d8a7c-24de-5f1c-b9b1-9b11ae0e3768
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business

Saved from https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business (rendered page text, built-in browser, 2026-10-07) POLICY ENDING THE WAR ON SMALL BUSINESS ← POLICY ARCHIVE ENDING THE WAR ON SMALL BUSINESS Small businesses create jobs, keep communities alive and give people the chance to build something of their own. They are an essential part of social mobility and the opportunity to build generational wealth. But the Democrats running California have spent years treating small businesses like a cash machine…or a problem to be managed - rather than a beautiful, vital part of our economic life and social fabric. Owners can owe the state $800 before earning a dollar. They spend hours dealing with rules nobody can understand and money defending extortionate shakedown lawsuits over footling technical discrepancies. Rents, energy and insurance bills keep rising, hiring gets more expensive and projects wait years for approval. It all adds up. Enough is enough. Steve Hilton is the candidate of small business, for small business. ‘Small business owner’ is his actual designation on the ballot. Steve has started and run a range of small businesses, including restaurants. He knows exactly what it’s like to try and stay afloat in the face of tiny margins, tough economic conditions and endless harassment and nonsense from government and bureaucratic agencies. Steve will end the Democrat war on small business, and give this essential part of our economy the freedom and support it needs. California’s small business owners have never had as passionate and committed a champion as Steve Hilton will be as governor. 1. CUT CALIFORNIA’S REGULATIONS BY MORE THAN HALF California has more than 420,000 regulatory requirements and prohibitions. By the end of his first term, Steve will bring that number below 200,000. Each state agency will have a public reduction target and will have to show its progress. A regulation should stay on the books only if it protects against a real harm and its benefit justifies its cost. Any major regulation expected to cost Californians $50 million or more will require an independent cost analysis and a public vote by the Legislature. Elected lawmakers should have to specifically justify regulations that impose undue costs on the public, with the default assumption that they are not justified. Starting a business will no longer mean chasing different agencies for registrations, licenses and permits. California will create one place to complete the state process, recognize comparable occupational licenses from other states and eliminate licenses that no longer serve a public-safety purpose. 2. END SHAKEDOWN LAWSUITS Trial lawyers and unions have turned California law into an extortionate shakedown racket. Small businesses are threatened with ruinous litigation over footling technical discrepancies, obviously manufactured complaints, and failure to comply with insane, pointless, bureaucratic processes created solely to generate more work for the trial lawyers who bribe the politicians that write these ridiculous laws. The legal process is engineered in a way that forces businesses to settle even when nobody has suffered real harm. It’s disgusting. Steve will enact real tort reform. PAGA will be ended by actually following the law as written, with the Labor Commissioner taking the first step in labor law enforcement, as laid out in Steve’s End PAGA plan, published last year. Employers who cheat their workers will still be punished. Private trial lawyers will no longer bring cases in the name of the state and collect enormous fees. A small business that makes an honest first-time mistake will receive clear notice and a reasonable opportunity to correct it before fines or lawsuits begin, provided the violation was not deliberate and caused no serious harm. The same protection will apply to construction-related accessibility claims. Businesses will still have to make their properties accessible, but an owner who promptly fixes a violation will not be forced to pay state statutory damages and attorneys’ fees. Fraud, repeated violations and conduct that puts people in danger will not qualify. 3. CUT THE COST OF EMPLOYING PEOPLE California forces private employers to navigate a separate workplace safety bureaucracy even though a national OSHA standard already exists. Steve’s Safe and Califordable Workplaces plan will move private employers to the federal OSHA baseline. California will keep a state plan for state and local government workers. This will reduce the cost of employing people, especially for small and fast-growing businesses. For a first-time, non-willful violation by a small business, the first response will be help rather than a fine. The business will receive plain-English guidance and 30 days to correct the problem. Written compliance questions will be answered within five business days. Employers who knowingly put workers in danger, retaliate against workers or repeatedly ignore violations will face tough enforcement. California-only rules that do not make workers safer or merely duplicate federal requirements will be repealed or rewritten. Workers’ compensation is supposed to help people injured on the job. Too much of the money is swallowed by lawyers, delays and fraud. Steve will set a first-term goal of cutting California’s workers’ compensation premium burden by at least 25 percent. Legitimate claims will move faster, the legal and administrative costs that drive up premiums will be cut, and fraud will be prosecuted. State Fund will also be reviewed and reformed if it is not lowering costs and helping injured workers. 4. ABOLISH THE $800 SMALL BUSINESS TAX California charges LLCs and many corporations at least $800 every year, even if the business loses money or never opens its doors. Steve will abolish this tax and veto any new state tax or fee that raises the cost of starting or running a small business. A business that earns no profit should not owe the state $800 simply for existing. 5. PAY OFF CALIFORNIA’S UNEMPLOYMENT DEBT California’s federal unemployment debt is driving up payroll taxes for employers every year through FUTA taxes (Federal Unemployment Tax Act). The most recent level is a 2.1% surcharge for every employee. This is an absolutely massive scandal, on so many levels. First, the tens of billions of dollars paid out by the Employment Development Department (EDD) should never have been needed in the first place: it was all a consequence of the cruel and counter-productive covid lockdowns, totally unjustified on any public health grounds, that viciously targeted small businesses while leaving many large businesses able to stay open. Secondly, the utter, disgraceful incompetence of the EDD led to over $30 billion being stolen in fraud, error and identity theft, including checks sent to prisoners on death row and United States Senators. It was an unforgivable dereliction of duty by Xavier Becerra’s Sacramento machine, and still no-one has been held accountable. Third, the gross negligence and incompetence of the Sacramento machine meant that California was the only state to not pay back its federal loan. And now every small business in our state is paying the price for the uselessness of our politicians and their appointed bureaucrats. Steve will pay off the debt by the end of his first term using savings from elsewhere in state government. Small businesses who were first penalized by the covid lockdowns should not be penalized again with a tax increase. Employers who did not create the debt will not be handed another state tax increase to cover it. Steve will also pursue legal remedies against Julie Su, now Deputy Mayor for Economic Justice under Mayor Mamdani in New York, and reduce the pay of all senior EDD officials who were working in the Department during this scandal. 6. PROTECT MAIN STREET FROM THEFT Retail theft is not victimless. Small-business owners pay through lost inventory, higher insurance premiums and added security costs. Proposition 36 will be fully funded and implemented, including the enforcement and treatment voters approved. Business owners should not have to accept theft as another cost of operating in California. Beyond these specific measures to help small business, Steve will cut the taxes, rules, lawsuits and other costs that make it so hard to run a small business in California. In particular, Steve’s other plans to cut energy costs will make a huge difference to every small business in California. Small businesses pay California’s high energy costs through their own gasoline and electricity bills and through the price of everything delivered to them. Steve’s Califordable energy plan will increase production in California and reverse rules that drive investment out of the state. The cost of every proposed energy regulation will have to be disclosed before it is adopted. California will not impose a vehicle mileage tax. The goal is $3.00 gas and cutting electric bills in half. ← Back to all policies

---
snapshot_id: 65764507-b7f6-53aa-9103-ffae3ed85d8f
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud

Saved from https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD ← POLICY ARCHIVE OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD THE PROBLEM The California State Auditor has warned that weak oversight has opened the door to organized healthcare fraud. Criminals can bill for care that never happened, including by using stolen patient information. Taxpayers lose the money, and the elderly and disabled people these programs are supposed to help can be left without the care they need. Stopping that waste is money the state can save. Steve Hilton and citizen investigator Eric Nissen went to a listed home-health agency in Hollywood and found a locked building, no entry listing for the agency, and a published telephone number that could not be reached. They found those red flags in minutes. State regulators need to check that agency's records and establish whether it has billed taxpayers and whether patients received care. It should not take a citizen knocking on the door to get those questions asked. HOW WE GOT HERE In 2022, the California State Auditor identified signs of large-scale, organized hospice fraud in Los Angeles County. One building in Van Nuys housed more than 150 licensed hospice and home-health agencies, more than the building could hold. The auditor found inadequate checks on licenses and staff credentials, slow investigations, and failures to coordinate between state departments. Those licensing failures sit with the California Department of Public Health. Medicare billing oversight sits with the federal Centers for Medicare & Medicaid Services. The officials who ran those systems owe taxpayers an explanation. Herb Morgan, who is running for State Controller, estimates billions of dollars in potential fraud, waste, and improper payments in Medi-Cal and In-Home Supportive Services, or IHSS. In his white paper, the Medi-Cal figure uses a roughly 10 percent improper-payment band drawn from federal CMS Payment Error Rate Measurement ranges. The IHSS figure uses 12 to 15 percent, reflecting self-reported hours and limited verification. Those are exposure estimates, not a count of proven fraud, and they are the starting point for where to look. California already has provider screening and electronic visit verification. Steve will require the agencies to use those records to check the care being billed and stop fraudulent payments. STEVE'S PLAN On Day One, as part of Operation Zero Waste, Steve will direct the Departments of Health Care Services and Public Health to review high-risk home-health and hospice agencies together. Investigators will check the owners and staff credentials, make unannounced visits to suspect offices, and match billing records to actual patients and services. Agencies must be able to show who delivered the care. When the evidence supports it, the state will suspend Medi-Cal payments, revoke licenses, and refer cases for prosecution. Investigators will trace connected companies so an excluded operator cannot simply reopen under another name, and send evidence of Medicare fraud to federal authorities. For IHSS and home-health visits, Steve will require closer checks of the hours claimed against authorized care and existing visit records. Repeated manual changes, impossible hours, and overlapping claims will trigger review and direct confirmation with the patient or an authorized representative. Live-in caregiver exemptions will be checked in suspicious cases. State agencies will match claims against death records, hospital stays, and excluded-provider lists, blocking clearly invalid claims such as services dated after a patient's death. Families providing genuine care will keep getting paid, with a prompt way to correct errors that could interrupt necessary care. Steve will require additional review before payment for providers with serious billing red flags, then extend those checks to medical transport, equipment, and behavioral-health services. His administration will pursue repayment from fraudulent providers and work with state and federal prosecutors on organized schemes. Medi-Cal health plans will have to account for recovered overpayments, with sustained reductions in improper spending reflected in future payments to plans. Otherwise, taxpayers could keep paying the same amount while the plans pocket the savings. Steve will work with Herb Morgan to check the financial results. When elected Controller, Herb will use the office's independent audit authority to examine high-risk payments and review the savings. He will publish the results under a radical-transparency standard: provider payments, recovery amounts, and exception patterns available to the public, with patient and caregiver identities fully protected. Steve is aiming for $5 billion a year in net savings to California's budget once the changes are in place. Public reports will show the California savings after enforcement costs, with federal savings and one-time recoveries listed separately. Only money California can save every year will be counted as ongoing savings. Within the first 100 days, inspections of suspect agencies and tighter checks on their claims will be underway. Over the following nine months, the administration will strengthen IHSS verification and connect the records needed to catch bad claims before payment. Within 18 months, the controls will extend across the targeted services. Steve will seek any legislation or federal approvals needed to finish the job, and publish the results as the work proceeds. A BETTER WAY FORWARD Families looking for home care should be able to reach the provider and trust that someone will turn up. Taxpayers should be able to see what they are paying for, without seeing anyone's medical record. Steve's administration will make providers and the departments overseeing them answer for that money. Radical transparency will put the financial results in public, and the savings will be reported in public. ← Back to all policies

---
snapshot_id: dd8a7ef8-8e24-5d3c-aaf5-027e71f78c7f
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/califordable-fixing-californias-insurance-crisis

Saved from https://stevehiltonforgovernor.com/policies/califordable-fixing-californias-insurance-crisis (rendered page text, built-in browser, 2026-10-07) POLICY CALIFORDABLE: FIXING CALIFORNIA’S INSURANCE CRISIS ← POLICY ARCHIVE CALIFORDABLE: FIXING CALIFORNIA’S INSURANCE CRISIS Steve Hilton’s Plan to Lower Costs, Restore Coverage, and Bring Insurers Back THE PROBLEM California’s insurance market is breaking down, and homeowners are paying the price. Across the state, people are losing coverage, facing sharp premium increases, or being pushed onto the FAIR Plan, where they pay more for less protection. What was designed as a last-resort safety net is now covering over 650,000 households. Not long ago, that number was closer to 100,000. For many Californians, the situation is getting worse fast. Policies are being non-renewed. Coverage is becoming harder to find. And when it is available, it is often significantly more expensive. This isn’t temporary. The system isn’t working. Fewer insurers are willing to operate in California. That means less competition, fewer choices, and higher costs for homeowners. In some parts of the state, the private market is barely functioning at all. Californians are being forced onto the unfair FAIR Plan, paying more for worse coverage, with no clear path out. The FAIR Plan was supposed to be a last resort. Today it’s a bad deal for hundreds of thousands of Californians. THE POLICY FAILURES BEHIND CALIFORNIA’S INSURANCE CRISIS This crisis is the result of years of failed policy decisions. The insurance market has been made unworkable. Rate approvals that are supposed to follow a clear timeline under Proposition 103 now drag on for months or even years, creating constant uncertainty for insurers that need to price risk in real time. When you make it impossible to operate, companies stop operating. The legal environment adds to the problem. Litigation is increasingly prolonged and, in many cases, financed by hedge funds, turning lawsuits into profit-driven investments that raise costs and delay recovery. Costs are also driven up from the ground level. Excessive regulation and permitting delays have made rebuilding far more expensive than it should be. As outlined in the housing plan, these policies have significantly increased construction costs across the state. Higher rebuilding costs mean higher insurance premiums. Public safety failures make things worse. Rising property crime, including organized theft and catalytic converter theft, has driven up auto insurance claims and costs, which insurers pass on to consumers. Taken together, these policies have created a market defined by high costs, high risk, and constant uncertainty. The result is fewer insurers, less competition, and higher prices for Californians. STEVE’S PLAN Fixing this starts with one thing: making the market work again. It starts with getting people off the unfair FAIR Plan and back into real insurance. As governor, Steve will: STABILIZE THE FAIR PLAN AND MOVE PEOPLE BACK TO REAL COVERAGE Get low- and moderate-risk homeowners off the FAIR Plan and back into standard policies, restoring it to its original role as a last-resort safety net. ENFORCE THE LAW ON RATE APPROVALS Make the existing 60-day timeline under Proposition 103 a real requirement, ending delays and procedural abuse so insurers can operate with predictability. CRACK DOWN ON HEDGE FUND-DRIVEN LITIGATION ABUSE Require transparency in third-party litigation financing and stop lawsuits from being used as profit-driven investments that raise costs and delay recovery. BRING INSURERS BACK INTO CALIFORNIA Make California a place insurers can actually do business again by creating a stable, predictable environment for pricing risk. ← Back to all policies

---
snapshot_id: 951117fe-1c12-5634-bf68-1c26dca31c33
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals

Saved from https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals (rendered page text, built-in browser, 2026-10-07) POLICY CRACK DOWN ON MASKED CRIMINALS ← POLICY ARCHIVE CRACK DOWN ON MASKED CRIMINALS Tougher Penalties for Criminals Who Deliberately Hide Their Identity THE PROBLEM Criminals who wear masks or disguises while committing robberies, burglaries and other serious crimes are not doing it by accident. They are trying to conceal their identity, avoid being recognized and make it harder for police to catch them. California law recognizes that this is wrong, but the penalty is hopelessly outdated. Penal Code Section 185 makes it a misdemeanor to wear a mask or disguise for the purpose of evading identification while committing a crime. The law dates back to the 19th century and still refers to disguises including “false whiskers.” That may have made sense when the law was written. It is not an adequate response to someone who deliberately masks up to commit a serious felony today. California should treat the deliberate concealment of a criminal’s identity for what it is: an aggravating factor that makes the crime more serious and makes it harder to solve. STEVE’S PLAN Steve will work to create new sentencing enhancements for criminals who deliberately conceal their identity while committing a felony. If prosecutors prove that someone committed or attempted to commit a felony while intentionally using a mask, hood, disguise or other facial covering to avoid identification, apprehension or prosecution, the criminal would face an additional one, two or three years in prison. For violent and serious felonies, the additional penalty would increase to two, three or five years. This would not restrict lawful mask wearing. It would apply only when prosecutors prove that the defendant was committing a felony and deliberately concealed their identity in order to help commit the crime or escape responsibility for it. Other states have already adopted similar laws. North Carolina, for example, increased penalties in 2024 for crimes committed while wearing a mask or disguise to conceal the offender’s identity. California should do the same. Someone who deliberately hides their identity while committing a serious crime has made an additional choice to evade law enforcement and avoid accountability. Our criminal law should recognize that choice and punish it accordingly. THE BOTTOM LINE California already has a law against concealing your identity while committing a crime. The problem is that the law is antiquated and the punishment is too weak. Steve will update it to make sure California once again backs law enforcement and comes down hard on criminals who deliberately try to hide who they are. If you deliberately mask up to commit a felony, you should face additional prison time. If you do it while committing a violent or serious felony, the penalty should be even tougher. ← Back to all policies