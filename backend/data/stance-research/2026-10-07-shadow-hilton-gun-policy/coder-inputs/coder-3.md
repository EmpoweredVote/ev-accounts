You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-gun-policy/labels/coder-3.json. Write JSON only, matching
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

### topic_key: gun-policy
topic_id: 56125933-b82a-46c5-847b-b2e9a146b89f  served_revision_id: 44615418-e111-4f2f-a256-92fcf74b0f2f
Question: How should the government regulate firearms?
  1. Ban civilian firearm ownership, except for tightly licensed hunting and sport use.
  2. Ban semi-automatic assault-style weapons, while allowing other firearms.
  3. Allow all types of firearms, but require universal background checks on every sale.
  4. Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines.
  5. Repeal major gun restrictions and let adults carry a firearm without a permit.

#### Annex

# gun-policy — served revision 44615418-e111-4f2f-a256-92fcf74b0f2f (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled …)_ carry an operator ruling (Chris Andrews).
Lines marked _(proposed)_ are a drafter's reading, not yet ruled. No `_owed:_` line is open. The season pin is an older revision (`1a72d5df-…`); coders code the
served text below.

**Question:** "How should the government regulate firearms?"

**Orientation:** standard. Rung 1 is the most restriction (a ban on civilian ownership), rung 5 the
least (repeal major restrictions, carry without a permit). The rungs order **how far the law
restricts which firearms civilians may own, buy and carry**. Each person sits at the furthest line
they would go: someone who wants universal checks **and** an assault-weapons ban wants more than
rung 3 allows ("all types"), so sits at rung 2.

**Levels with a lever:** federal, local, state. The lever is state and federal
law. Most states forbid local gun ordinances, so a local lever exists only where state law allows one.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "assault weapon", "assault-style", "semi-automatic", "large-capacity magazine",
"universal background checks", "private sale", "gun-show loophole", "transfer", "concealed carry",
"permitless carry" / "constitutional carry", "reciprocity", "National Firearms Act" (NFA),
"suppressor", "red flag" / "extreme risk protection order", "safe storage", "ghost gun".

1. **"Ban civilian firearm ownership, except for tightly licensed hunting and sport use."**
   - Means: civilians may not own firearms, apart from tightly licensed hunting and sport guns.
   - Operative clauses: [a] ban civilian ownership; [b] the only exception is tightly licensed hunting
     and sport use.
   - Establishing evidence looks like: own words or an instrument that bans civilian ownership in
     general. A ban on one class of firearm is not this rung.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: a broad assault-weapons ban is still a ban on one class.

2. **"Ban semi-automatic assault-style weapons, while allowing other firearms."**
   - Means: assault-style semi-automatic weapons are banned; other firearms stay legal.
   - Operative clauses: [a] ban semi-automatic assault-style weapons; [b] allow other firearms.
   - Establishing evidence looks like: a single-subject assault-weapons ban. A ban written as a
     definition or list of the banned weapons meets [b]: the definition is the boundary, and the
     instrument leaves other firearms legal.
   - A bill that extends an existing assault-weapons ban to more weapons → rung 2.
   - Levels that hold a lever: federal; state; local where state law allows.
   - Known chair-shaped instruments: the Assault Weapons Ban of 2025 (S.1531 / H.R.3115), named in the
     topic note _(proposed: chair-shaped as filed)_.
   - A **magazine-capacity limit** alone is not a ban on a class of weapon → `direction-only`
     _(proposed)_.

3. **"Allow all types of firearms, but require universal background checks on every sale."**
   - Means: no type of firearm is banned, and every sale, private sales included, needs a background
     check.
   - Operative clauses: [a] allow all types of firearms; [b] universal background checks on every
     sale.
   - Establishing evidence looks like: a universal-checks bill **plus** evidence that the person
     opposes bans on a type of firearm (a No on an assault-weapons ban, own words). [a] must be shown;
     a checks bill is silent on bans (V4.2 "Silence is not a clause"). Compound: one side only →
     `compound-partial`. Not finding a ban cosponsorship is not evidence for [a] (H14) _(ruled 2026-10-01)_.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_. The Background Check Expansion Act (S.3214),
     named in the topic note, meets [b] only.
   - Checks for some sales only (gun shows, buyers under 21) are not "every sale" → `direction-only`
     _(proposed)_.

4. **"Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across
   state lines."**
   - Means: keep current gun laws, with no new limits; the furthest change is easier carrying, such
     as recognizing other states' carry permits.
   - Operative clauses: [a] no new restrictions; [b] at most, loosen carry rules (the major laws
     stay).
   - Establishing evidence looks like: own words against new restrictions, and a record that loosens
     carry rules without repealing major laws. The 4 / 5 line is whether the major laws stay _(ruled
     2026-09-08)_.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_. The Constitutional Concealed Carry Reciprocity
     Act (S.65 / H.R.38), named in the topic note, meets the "loosen carry" part of [b].
   - A reciprocity bill as the only record → BLANK `direction-only`. It meets the "loosen carry"
     part of [b], but one loosening law cannot show "at most" (V2, 2026-09-26) or "no new
     restrictions" (V4.2). Seat rung 4 only with a second passage: own words, or a recorded vote
     against a new restriction or against a repeal. This replaces the 2026-09-08 seating rule _(ruled 2026-10-01)_.
   - Not finding a rung-5 record is not evidence for rung 4 (V4.2 "Ruling out the other rungs").

5. **"Repeal major gun restrictions and let adults carry a firearm without a permit."**
   - Means: repeal the major gun laws, and let adults carry with no permit.
   - Operative clauses: [a] repeal major gun restrictions; [b] permitless carry for adults.
   - Establishing evidence looks like: a repeal of a major restriction (for example the federal NFA
     rules on suppressors or short-barrelled rifles, a state registration or assault-weapons ban)
     **and** permitless carry _(proposed)_. Compound: one side only → `compound-partial` (V4.2). For a
     state officeholder, see the state rule below.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **For a state officeholder**, a state law that removes the state's license or permit to carry
     meets **both** clauses: the carry license is the major restriction the state controls → rung 5.
     **For a federal officeholder**, [a] still needs repeal of major federal laws; a federal
     permitless-carry or reciprocity measure alone → `compound-partial` _(ruled 2026-10-01)_.

**Hard cases:**
- **Rules about how guns are stored, marketed or advertised** (safe storage, advertising to minors)
  do not say which guns may be owned or who may buy them → V2 `adjacent`; BLANK `no-evidence` when
  nothing else survives. A Yea and a No on such a bill are the same: the direction of the vote does
  not make it on-question.
- **Red-flag laws, waiting periods, minimum ages, ghost-gun rules** restrict but do not match a rung
  clause → `direction-only` _(proposed)_.
- **Preemption (codebook V2, H12).** A state law that voids local gun ordinances decides which level
  may act → `adjacent`.
- **Budget and omnibus votes** with a firearms item → V4 `multi-subject`.


## Sources

---
snapshot_id: bdd72c13-8ad2-51a4-bba1-19d7cbfa3c00
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/restoring-second-amendment-rights-in-california

Saved from https://stevehiltonforgovernor.com/policies/restoring-second-amendment-rights-in-california (rendered page text, built-in browser, 2026-10-07) POLICY RESTORING SECOND AMENDMENT RIGHTS IN CALIFORNIA ← POLICY ARCHIVE RESTORING SECOND AMENDMENT RIGHTS IN CALIFORNIA Steve Hilton’s Plan to Defend the Constitutional Rights of Law-Abiding Citizens THE PROBLEM The Second Amendment guarantees Americans the right to keep and bear arms. But after 16 years of one party rule, California Democrats have passed some of the most restrictive gun laws in the country. Instead of focusing on criminals who misuse firearms, Democrats in state government have targeted law abiding citizens with layer after layer of regulation. At the same time, the ability to obtain a concealed carry permit often depends on which county someone lives in. Some counties follow the law. Others impose delays and barriers that effectively deny residents their constitutional rights. Attorney General Rob Bonta has repeatedly defended these restrictions in court, including California’s ban on standard capacity magazines in Duncan v. Bonta and California’s so-called “assault weapon” ban in Miller v. Bonta. Californians deserve a governor who will defend their constitutional rights. STEVE HILTON’S PLAN Steve Hilton will take immediate action to restore Second Amendment rights in California, working in close partnership with his ‘Golden Ticket’ running mate, Attorney General candidate Michael Gates. When Californians elect Michael Gates as Attorney General, California will finally have a Governor and Attorney General aligned in defending constitutional rights instead of attacking them. 1. BRING CALIFORNIA STATE GOVERNMENT INTO COMPLIANCE WITH THE SECOND AMENDMENT As governor, Steve Hilton will issue an executive order directing all state agencies to work with Attorney General Gates to review their policies, regulations, and enforcement practices to ensure they comply with the Second Amendment and recent Supreme Court rulings. This order will require state agencies to work with the Attorney General to identify policies that conflict with the Constitution and take steps to bring those policies into compliance. 2. ENSURE CONCEALED CARRY LAWS ARE APPLIED CONSISTENTLY ACROSS CALIFORNIA California law allows residents to obtain concealed carry permits, but access to those permits varies widely depending on where someone lives. As governor, Steve Hilton will direct Attorney General Gates to ensure every county in California complies with federal and state concealed carry law, including the standards established by the Supreme Court’s decision in New York State Rifle & Pistol Association v. Bruen. Attorney General Gates will work with county sheriffs and local officials to ensure concealed carry permitting is applied fairly and consistently across the state. The Constitution should apply equally in every county in California. 3. REVIEW CALIFORNIA’S FIREARM LAWS FOR CONSTITUTIONALITY California has enacted hundreds of firearm related laws over the past several decades. Many of these laws were written before recent Supreme Court decisions clarified the scope of Second Amendment protections. As governor, Steve Hilton will direct the Governor’s legal team to conduct a comprehensive review of California’s firearm laws to determine which restrictions are unconstitutional under current Supreme Court precedent. Instead of spending taxpayer money defending laws that violate the Constitution, California should focus on enforcing laws against violent criminals. A SIMPLE PRINCIPLE The Second Amendment is part of the Constitution. California should respect it. Steve Hilton will restore Second Amendment rights in California while ensuring laws are applied fairly and consistently across the state. ← Back to all policies

---
snapshot_id: ed7070f0-4ca7-5a64-bd4f-c6d7e0398384
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud

Saved from https://stevehiltonforgovernor.com/policies/cracking-down-on-medi-cal-fraud (rendered page text, built-in browser, 2026-10-07) POLICY OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD ← POLICY ARCHIVE OPERATION ZERO WASTE: CRACKING DOWN ON MEDI-CAL FRAUD THE PROBLEM The California State Auditor has warned that weak oversight has opened the door to organized healthcare fraud. Criminals can bill for care that never happened, including by using stolen patient information. Taxpayers lose the money, and the elderly and disabled people these programs are supposed to help can be left without the care they need. Stopping that waste is money the state can save. Steve Hilton and citizen investigator Eric Nissen went to a listed home-health agency in Hollywood and found a locked building, no entry listing for the agency, and a published telephone number that could not be reached. They found those red flags in minutes. State regulators need to check that agency's records and establish whether it has billed taxpayers and whether patients received care. It should not take a citizen knocking on the door to get those questions asked. HOW WE GOT HERE In 2022, the California State Auditor identified signs of large-scale, organized hospice fraud in Los Angeles County. One building in Van Nuys housed more than 150 licensed hospice and home-health agencies, more than the building could hold. The auditor found inadequate checks on licenses and staff credentials, slow investigations, and failures to coordinate between state departments. Those licensing failures sit with the California Department of Public Health. Medicare billing oversight sits with the federal Centers for Medicare & Medicaid Services. The officials who ran those systems owe taxpayers an explanation. Herb Morgan, who is running for State Controller, estimates billions of dollars in potential fraud, waste, and improper payments in Medi-Cal and In-Home Supportive Services, or IHSS. In his white paper, the Medi-Cal figure uses a roughly 10 percent improper-payment band drawn from federal CMS Payment Error Rate Measurement ranges. The IHSS figure uses 12 to 15 percent, reflecting self-reported hours and limited verification. Those are exposure estimates, not a count of proven fraud, and they are the starting point for where to look. California already has provider screening and electronic visit verification. Steve will require the agencies to use those records to check the care being billed and stop fraudulent payments. STEVE'S PLAN On Day One, as part of Operation Zero Waste, Steve will direct the Departments of Health Care Services and Public Health to review high-risk home-health and hospice agencies together. Investigators will check the owners and staff credentials, make unannounced visits to suspect offices, and match billing records to actual patients and services. Agencies must be able to show who delivered the care. When the evidence supports it, the state will suspend Medi-Cal payments, revoke licenses, and refer cases for prosecution. Investigators will trace connected companies so an excluded operator cannot simply reopen under another name, and send evidence of Medicare fraud to federal authorities. For IHSS and home-health visits, Steve will require closer checks of the hours claimed against authorized care and existing visit records. Repeated manual changes, impossible hours, and overlapping claims will trigger review and direct confirmation with the patient or an authorized representative. Live-in caregiver exemptions will be checked in suspicious cases. State agencies will match claims against death records, hospital stays, and excluded-provider lists, blocking clearly invalid claims such as services dated after a patient's death. Families providing genuine care will keep getting paid, with a prompt way to correct errors that could interrupt necessary care. Steve will require additional review before payment for providers with serious billing red flags, then extend those checks to medical transport, equipment, and behavioral-health services. His administration will pursue repayment from fraudulent providers and work with state and federal prosecutors on organized schemes. Medi-Cal health plans will have to account for recovered overpayments, with sustained reductions in improper spending reflected in future payments to plans. Otherwise, taxpayers could keep paying the same amount while the plans pocket the savings. Steve will work with Herb Morgan to check the financial results. When elected Controller, Herb will use the office's independent audit authority to examine high-risk payments and review the savings. He will publish the results under a radical-transparency standard: provider payments, recovery amounts, and exception patterns available to the public, with patient and caregiver identities fully protected. Steve is aiming for $5 billion a year in net savings to California's budget once the changes are in place. Public reports will show the California savings after enforcement costs, with federal savings and one-time recoveries listed separately. Only money California can save every year will be counted as ongoing savings. Within the first 100 days, inspections of suspect agencies and tighter checks on their claims will be underway. Over the following nine months, the administration will strengthen IHSS verification and connect the records needed to catch bad claims before payment. Within 18 months, the controls will extend across the targeted services. Steve will seek any legislation or federal approvals needed to finish the job, and publish the results as the work proceeds. A BETTER WAY FORWARD Families looking for home care should be able to reach the provider and trust that someone will turn up. Taxpayers should be able to see what they are paying for, without seeing anyone's medical record. Steve's administration will make providers and the departments overseeing them answer for that money. Radical transparency will put the financial results in public, and the savings will be reported in public. ← Back to all policies

---
snapshot_id: 0d88ac44-2954-5c85-86a4-8249fd3d424c
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/bring-hollywood-home

Saved from https://stevehiltonforgovernor.com/policies/bring-hollywood-home (rendered page text, built-in browser, 2026-10-07) POLICY BRING HOLLYWOOD HOME ← POLICY ARCHIVE BRING HOLLYWOOD HOME Steve Hilton’s Plan to Revive and Grow California’s Film and Television Industry THE PROBLEM California invented the entertainment business. Hollywood became the global center for film and television, supported by world-class talent, crews, studios, and infrastructure. But that advantage is slipping away. Production is leaving California for states and countries offering better incentives, lower costs, and more predictable systems—including Georgia, New York, New Jersey, New Mexico, Canada, the UK, and Australia. This is not about celebrities—it’s about jobs. Thousands of middle-class workers depend on the industry: Camera operators Electricians Editors Set builders Drivers Costume designers Small businesses supporting production When productions leave, those jobs leave too. The damage is already clear: Roughly 51,000 jobs lost in three years Soundstage occupancy in Los Angeles has dropped from over 90% to about 62% The lights are literally going out in Hollywood. WHY THIS IS HAPPENING California has fallen behind competitors that offer: Stronger, more flexible incentives Faster approvals Greater certainty for producers While California increased its tax credit program to $750 million annually, the system still has major flaws: Rigid application windows Complex categories Limited access for smaller productions Other regions operate faster, simpler, and more competitive systems—often without caps. California is still acting like Hollywood has nowhere else to go. It does. THE GOAL Restore California as the best place in the world to make film and television— Bring Hollywood Home . The goal is not nostalgia—it’s economic reality. By the 2028 Olympics in Los Angeles, California should reestablish itself as the global center of production. This means: Rewarding productions that hire California workers Supporting local facilities and communities Competing globally instead of managing decline THE PLAN 1. MAKE CALIFORNIA COMPETITIVE AGAIN California must compete globally with stronger, more reliable incentives. Key changes: Move to an uncapped, open production incentive system Cover both above-the-line and below-the-line costs Include post-production work This ensures producers choose California because it makes business sense—not because they win a lottery. The plan also explores: Federal tax incentives Temporary “kick-start” incentives Enhanced incentives for key zones and independent productions 2. GIVE PRODUCERS CLARITY AND CERTAINTY Production requires predictable timelines—not bureaucratic delays. Reforms include: Continuous, rolling approval system Automatic certification within 30 days Streamlined permitting processes Additional steps: Enforce deadlines on agencies Refund fees if deadlines are missed Appoint a Governor’s Expediter to cut through bureaucracy No more waiting. No more guessing. 3. PROTECT INDEPENDENT AND MID-SIZED PRODUCTIONS Current programs often favor large studios while smaller productions struggle. The plan will: Reserve funding for independent and mid-budget projects Ensure smaller producers are not crowded out A healthy industry needs both major productions and independent creators. 4. MAKE THE INCENTIVE REAL Tax credits must translate into real financial value. Reforms include: Expanding direct rebates Improving transferability Ensuring credits are usable and bankable The plan also calls for federal partnership to compete internationally, including: National production incentives Support for major events (Olympics, World Cup) Investment in studio and venue infrastructure 5. PROTECT CALIFORNIA’S CREATIVE FUTURE The issue isn’t just production—it’s ownership and control. Independent creators increasingly lose rights and long-term value through financing structures. The plan will: Support creative ownership Strengthen independent production Work with industry stakeholders to maintain a balanced ecosystem California should be a place where creators build and own , not just work. THE BOTTOM LINE Hollywood should not be leaving Hollywood. California still has: The talent The workforce The infrastructure The global brand What it has lacked is leadership. Bring Hollywood Home is about restoring: Jobs Opportunity One of California’s defining industries California invented the entertainment business. It’s time to win it back. ← Back to all policies

---
snapshot_id: 7f8d44c5-d27c-52e6-a51f-9609caf69d15
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la

Saved from https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la (rendered page text, built-in browser, 2026-10-07) POLICY WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA ← POLICY ARCHIVE WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA A world-class pathway to technology entrepreneurship and business leadership THE PROBLEM California has some of the best universities in the world. But for millions of working Californians, the opportunity they represent is increasingly out of reach. We have among the highest poverty and unemployment rates in America. Social mobility in many parts of our state, and for millions of young Californians, seems to have ground to a halt. California used to offer young people opportunity better than anywhere else in the world. Far too many young Californians today feel as if the only option is to be stuck here with no prospect of ever owning a home, or starting a business – or moving to another state. That failure is especially stark in East LA. A teenager in Palo Alto grows up surrounded by founders, engineers, investors, and people who expect them to aim high. A teenager in East LA may have just as much talent and drive, but far less exposure to those industries, those networks, and those expectations. In East Los Angeles, only 11.4 percent of adults over 25 have a bachelor’s degree, and more than 17 percent live in poverty. Too many talented young people are never shown a credible route from where they are to a career in technology or finance, or to starting a high-growth company of their own. There is nothing wrong with building a restaurant, working in music, or joining a family business. Those are part of the strength of East LA. But they should not be the only visible paths. Young people in East LA should see the same horizon as young people growing up around Silicon Valley: technology, venture capital, finance, product development, and high-growth, high reward entrepreneurship. California’s answer has usually been another workforce program. That is not enough. East LA does not need a second-tier program with lower expectations. It needs an elite institution built to recognize talent, raise aspiration, and open doors. HOW WE GOT HERE California has built a two-tier education system. Students from affluent communities get access to elite universities, powerful alumni networks, prestigious internships, and the confidence that comes from being told they can lead. Working-class students are too often steered toward basic job training and told to be “realistic.” Business success depends on more than classroom instruction. It depends on exposure, mentors, relationships, confidence, and access to capital. Young people absorb what is possible from the people and institutions around them. If they never meet a founder, investor, engineer, or executive, those careers can feel as if they belong to someone else. California’s leading universities regularly promise to expand access and serve the communities around them. Some have begun. UCLA Extension has partnered with the SoLa Foundation to offer tuition-free UCLA courses in South Los Angeles. That is a good start. But a collection of short courses is not the same as an elite, aspirational business school with a rigorous curriculum, a respected credential, a powerful network, and a direct path to building and leading a company. STEVE’S PLAN Steve Hilton will launch an elite, locally rooted business school in East Los Angeles through a competitive partnership with one of California’s leading universities. It will be elite in quality, not restricted by wealth. Students will be admitted for their talent, drive, creativity, and potential, and the program will be tuition-free for income-qualified California residents. BRING AN ELITE UNIVERSITY TO EAST LA UCLA, USC, Claremont McKenna and other leading public and private universities will be invited to compete to become the school’s founding academic partner. The selected university will put its name and academic standing behind the school, design the curriculum, provide faculty and visiting instructors, and open its alumni, employer, and industry networks to students. This will not be a satellite office with a famous logo on the wall. Students will earn a respected university credential and transferable academic credit, with a clear path to further study at the partner university, or another equivalently high-status institution. SET ELITE STANDARDS AND FIND OVERLOOKED TALENT The school will recruit aggressively from East LA high schools, community colleges, churches, and community organizations. Admissions will look beyond family connections and narrow measures of academic success to identify initiative, resilience, creativity, leadership, and the determination to build something. The standards will be demanding. Students who need additional preparation will receive it through a summer bridge program, tutoring, and academic support. The answer to unequal opportunity is not a watered-down curriculum. It is giving talented students the support they need to meet an elite standard. TEACH STUDENTS HOW COMPANIES ARE BUILT Students will study entrepreneurship, finance, accounting, marketing, sales, product development, operations, artificial intelligence, data, leadership, and communication. The goal is not to train students for one narrow job. It is to teach them how a company is created, financed, managed, and scaled. Every student will work on a real company, product, or business plan. They will test ideas with customers, build a budget, make a pitch, and learn from success and failure. Students who want to grow an existing family business will be able to use the same tools to take it further. OPEN THE NETWORK California founders, executives, investors, engineers, accountants, and attorneys will serve as mentors and instructors, and every student will receive paid work experience with a technology company, startup, investment firm, or growing California business. The school will also host founders and investors in residence and regular pitch sessions. Students will leave with relationships, references, experience, and people prepared to open doors for them. GIVE STUDENTS THE CHANCE TO BUILD The school will include a business incubator where students and graduates can develop companies with access to workspace, legal and accounting support, market research, and experienced advisers. A privately backed seed fund will give promising student ventures the chance to compete for early investment. Public dollars will support education. Private investors will decide which businesses to back. REMOVE THE PRICE BARRIERS For income-qualified students, support will cover tuition, books, technology, transportation, and childcare. The school will offer a full-time program, flexible options for working students, and a summer academy that introduces local high school students to technology, entrepreneurship, and business leadership before they choose a college or career path. START IN EAST LA AND PROVE IT WORKS Steve will fund the East LA pilot in his first budget by bringing together existing higher education and workforce resources with matching support from the university partner, employers, and philanthropy. There will be no new state bureaucracy, and no new tax. The first class will begin during Steve’s first term. The state will publish results including completion, transfer, paid internships, job placement, starting pay, companies launched, and outside capital raised. If the model works in East LA, California will take it to other working-class communities across the state. A BETTER WAY FORWARD The point is not to train young people in East LA for the jobs others have decided are “realistic” for them. The point is to give them access to the same knowledge, networks, and expectations that have helped create generations of California business leaders. A young person in East LA should grow up believing they can found the next great California company, finance it, build it, and lead it. Talent is already there. This school will match that talent with elite opportunity: from working class to founder class. ← Back to all policies

---
snapshot_id: 43da1a1f-50af-5ef9-b4b6-9644700a64ef
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN - OTR page: https://ontherecord.empowered.vote/meetings/25962209-b5fc-432b-9054-02559fbeeb28 - Video: https://www.youtube.com/watch?v=CKu9rBJTNYw - Date on On the Record: 2026-05-29 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:14] >> Are we ready to save our beautiful state of [0:37] >> Democracy is under threat. >> Everyone agrees we need change. That's what I'm fighting for. [1:17] >> We can turn things around. You just have [7:39] >> So Caitlyn and Alex, it's interesting. We've already seen a couple of things that we'll probably see a lot of in this debate, which is the Democrats who are here who've been responsible for 16 years of one party rule for everything that we see in California won't take responsibility and all they can talk about is Trump. Look, I was asked how I'm preparing for this debate the other day. And my answer was the meetings, the thousands of people that have come to our events the last year in California. I've traveled to every part of the state. I've seen the struggle and the stories and that is my struggle and my stories. My parents were immigrants. The California dream is my dream and I want that for every single one of you watching out there. We can get it [8:39] >> So, they should vote for the candidate who's got a concrete plan to make our state calffordable. $3 gas, cut your electric bills in half, your first hundred grand taxfree, a home you can afford to buy. It's common sense, practical things. Most of my career has been in business. I know how to get things done. And we need to change. We need some fresh thinking. after 16 years of one party rule from these Democrats that have given us the highest poverty rate as you mentioned the highest unemployment rate and the highest cost of living in the country. [10:06] ahead. >> It's not Donald Trump who's given us gas prices $2 higher than the rest of the country. It's Democrat policies, which Antonia and all the Democrats here support. It's not Donald Trump that's given us the highest housing costs in the country. It's Democrat policies that all these Democrats support. Donald Trump is the president in all the other states of America where the cost of living is way lower than in California. Obviously, it is way past time for change in California and endlessly going on about Donald Trump doesn't serve the needs of the struggling families and small businesses. >> Can you say whether or not he won the election? [14:23] Hilton. >> So, so Matt says that it's obviously impossible to get to $3 gas. Um, as I have laid out in my plan, before the Iran war, there were 40 states in America with $3 gas or lower, most of the which don't have the abundant oil reserves that we have in California. But because of the policy supported by Matt and all these Democrats, we are now shipping oil halfway around the world, 7,500 miles from places like Iraq instead of opening up California oil and gas production so we can reduce costs and get $3 gas in California, which is my plan. [15:00] >> Secretary Bera. [24:05] >> It is. There's there's a very simple truth uh which everyone in California knows which is that taxes are too high and we need taxes to be lower and they're especially too high for working people in California. You got people on 70 80 90 grand in California which doesn't get you very far who are paying 9.3% state income tax. That is higher than the top rate in most other states. That's why my plan eliminates state income tax under 100 grand. And by the way, if you think that it can't get worse in California, I've got two words for you. Tom Styer. Under Tommy Styer, the taxes will be higher. Gas prices will be higher. Everything will be higher with Styer. [26:43] >> Thank you, [29:29] >> So I'm I'm the only immigrant on stage. I'm a legal immigrant and Americans support immigration when it is properly controlled. And what we saw under the Biden administration, open borders undermined everybody's support for immigration. And as governor, I've made it very clear although it is the federal government's responsibility to to um determine and implement immigration policy, I think it's important that all the laws are peacefully enforced. And as governor, I would make sure that we work with the federal government to enforce our laws. Expect [30:11] workers? >> The the policy on deportation is the exact same policy that we saw with President Obama. In fact, the numbers of deportations right now in our country and in California are slightly just to clarify your point. Can you answer the question? I answered the question which is I will work. >> Will you deport him? >> That was the question. >> Well, would you Antonia? Because the governor of California, as you know, doesn't make that decision. It is the president of the United States elected by the country. [34:43] >> I I don't want to respond to to silly name calling, but I'd like to actually respond to something Katie said, and I think it's probably a sincere policy um difference between us. She said something very revealing which is the only way really that California's economy has been growing in the last few years is through illegal immigration. And I just don't think that's the right way for us to be growing. I think we need to help small businesses create jobs and opportunity and for Californians to be able to earn more and live the California dream and for entrepreneurs to want to start businesses in California. That's how we should be growing our economy, not by [35:23] consequences of that decision, >> Katie, it's I there's a difference I think you'll accept between legal and illegal immigration. [43:18] Hilton, >> um Antonio mentioned uh me earlier and said I just recently arrived. It's true. I arrived here in 2012 with my wife and my two sons. But what's interesting is that um I don't think there's an appreciation of the difference between legal and illegal immigration. I've spent many many times right here in East LA where we are with legal immigrants with families of legal immigrants who really resent the unfairness that we're seeing in California where you have illegal immigrants who are getting free benefits, housing, welfare, and they say to me, "Look, we did it the right way. We worked hard. the right way. Candidates, don't worry. >> We are not getting fairness and we need to restore fairness in our [45:34] >> I think the next governor of California will have to work with the administration and with the president that the American people elected to get good results for Californians. And by the way, my attitude will be to work with the president regardless of party to get good results for Californians. Now, it so happens that we have a president who has endorsed me for governor, and we've discussed how I can work with his team to lower gas prices in California by opening up energy production, to reduce wildfire risk, by proper forest management, to get the fraud and the waste out of our state budget so we can cut taxes. These are all practical ways we can work together to help everyone. >> Thank you, Mr. California. [55:54] singlepayer healthcare. >> Just listen to these Democrats arguing about whether to go left or even further left when that's the direction that's got us into this mess, the highest cost, the highest taxes in the country. I'm the only person here with actual experience of singlepayer healthcare. Both as a patient and as a policy maker. As a patient, it nearly killed me. That's another story we don't have time for. As a policy maker, you end up with the worst patient satisfaction, cost that you can't afford, taxes skyhigh to pay for it. It is a total disaster. And the actual way we deal with health care in this state is to at least stop spending $20 billion a year on free health care for illegal immigrants who [64:17] Court has stopped you from being able to [64:21] that's a lie. My my view is that it's a bit rich for Javier to talk about following the law when he is mired personally in a corruption scandal where his former chief of staff Shan McCcluskey when Javier was appointed by Joe Biden to be health secretary he wanted his chief of staff to go with him. The salary wasn't enough. So what did they do? They took money from Javier's campaign account to top up his salary by funneling it to Dana Williamson, Gavin Newsome's former chief of staff, so that it was paid to this guy's wife. All of that is illegal. It is against state law. It's against federal law. My running mate for attorney general, Michael Gates, has this evening written to Javier Bera to make it clear that when he is attorney general, Javier will be investigated and if necessary, prosecuted for these crimes. [65:21] >> I'm not going to weigh in on something that I don't have the knowledge of the facts on. I trust that Chad is interested in what we should all be interested in, which is ensuring the integrity of our elections and restoring faith in our elections in California. That's why I support voter ID in California. Let's see what these Democrats think of voter ID. [66:24] chief And it was your decision. [66:29] Washington as health secretary and you wanted him by your side. And the reason that the money was transferred is because the salary wasn't high enough. That's why you engaged in this scheme which is [67:47] >> And just today, I launched a new plan for starter homes in California. One of the most heartbreaking things I see is young people, they come to our events and I asked them, "Do you ever see yourself owning a home in California, starting a family here?" And they say, "No, and we're going to have to leave." And that's why we've got to enact a very straightforward plan. Number one, we have to get rid of the regulations that make it two or three times as expensive to build the exact same home in California as in neighboring states. We have to stop the lawsuits filed by the unions who support these Democrats that get in the way of building housing. And to your point, we have to stop trying to force housing into suburban neighborhoods where people don't want it. Instead, we have to build single family homes in the places in our state that do want to expand. That's the plan to make sure that we can restore that California dream of home ownership. It is the heart of opportunity for our young people and it's being taken away by these Democrats and their policies. >> Mayor Mayanm, your response. [81:02] >> Mr. [81:04] Hilton, >> look, this is a very serious moment for California. The ballots are out. They're in your hands. And we have a really big choice to make, which is do we go for another four years of one party rule that's given us the highest taxes for the worst results, the highest poverty rate, highest unemployment rate, highest cost of living, serious policy questions, homelessness. We need to stop homelessness and end it. We need to stop funding fiascos like highspeed rail. We need to lift burdens on our business. That's what this debate needs to be about. And the only way to get the change we need is to [86:13] >> It's classic Democrats, isn't it? What you're hearing. Um, if it moves, tax it. If it still moves, regulate it. And if it stops, move it. I guess they want to subsidize it. Look, the truth is on this we have to have a bit of humility. This is a very fastmoving technology and actually even the people involved in it disagree about its exact consequences. Here are two things that we two practical things we could and should be doing better today. First of all, the real bluecollar jobs that are coming from the AI revolution, they're not happening in California. They're going to Texas and Arizona semiconductor manufacturing. We could get that back by removing regulations. And secondly, our school system is not educating our kids to be able to thrive in the world of AI. We need to [89:30] >> I think that was my word. Would you like [89:32] that charge? >> Again, I don't want to respond to silly insults, but I'll take the substantive point, which is first of all, when Tom talks about um uh tripling subsidies for electric vehicles, let's be clear what that is. That is higher taxes on hardworking Californians driving their gas, cars, and trucks every day so that Tom's rich friends can feel virtuous about saving the climate. The truth is, we need common sense on climate change. It doesn't make sense to import oil from halfway around the world, increasing carbon emissions in the name of climate. It doesn't make sense to allow mega wildfires in our forests that actually release more carbon dioxide than what is saved by all these climate policy. [96:06] Hilton. >> Um, so highspeed rail is an example of the fraud. Um, they've spent billions of dollars. I don't know where the money's gone. It certainly hasn't gone into building anything that actually works. And I just want to make one broader point about fraud. I'm actually running this race in a different way than we've seen before. I've put together a team to run with me. There are other statewide offices. And along with my running mate for state controller, Herb Morgan, and Michael Gates for attorney general, and Gloria Romero for Lieutenant Governor, we've actually been investigating the fraud. Our survey so far suggest that there in the last five years in California, we've had $425 billion dollars of fraud. That's around 80 billion a year, around 20% of the budget. And our team is going to stop it and prosecute it and give money. [96:54] >> real quickly, mayor. [99:59] I guess that would be a good one. [100:00] Clint Eastwood. >> Okay. Mr. Hilton. >> I think there's only one choice really. Jason [102:45] rest of the state? Well, um, if you ask my wife and my sons, often to their great embarrassment, it's that I absolutely hate bureaucracy and ridiculous, pointless rules and regulations that crush the life out of uh, people and businesses and daily experience that we have. And so, I just want to tell everyone, I'm going to be relentless, absolutely relentless in fighting the nonsense that makes life so difficult for each and every one of you. I will not rest until we restore sanity to our beautiful state of

---
snapshot_id: d8d0d177-5257-5e43-894a-804d6826df81
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/making-californias-public-colleges-affordable-again

Saved from https://stevehiltonforgovernor.com/policies/making-californias-public-colleges-affordable-again (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA’S PUBLIC COLLEGES AFFORDABLE AGAIN ← POLICY ARCHIVE MAKING CALIFORNIA’S PUBLIC COLLEGES AFFORDABLE AGAIN The Califordable Hilton-Romero Plan to Cut Costs, Cut Bureaucracy, and Help Students Get Ahead THE PROBLEM California’s public colleges were supposed to be a ladder up. For too many families, they have become just another cost trap driven by rising tuition and outdated timelines that force families to pay more. Costs keep going up, and families have no way to keep up. At the California State University system, undergraduate tuition is now $6,450 a year, with another increase already scheduled. At the University of California, tuition for new in-state undergraduates is $15,588, and the university estimates the total annual cost can reach about $47,000 once housing, meals, books, transportation, and other expenses are included. Even California Community Colleges, often sold as the cheap option, charge $46 per unit in enrollment fees, or $552 for a full-time 12-unit semester, before books, commuting, and everything else. And the problem is not just price. It is waste and falling standards. Students are pushed into longer timelines, cannot get the classes they need, and lose time and money trying to transfer credits. In the California State University system, only about 35 percent of first-time students graduate in four years. HOW DEMOCRATS BROKE IT This happened on the Democrats’ watch. After years of one-party rule, California’s public colleges have gotten more expensive, more bloated, with lower standards and less accountability. Tuition keeps going up, costs keep rising, and Democrats have done nothing to stop it. Instead of forcing these institutions to control costs and modernize how students move through college, Democrats protected the status quo. Families pay more. Students wait longer. Bureaucrats win. THE PLAN OFFER FASTER, LOWER-COST THREE-YEAR DEGREES California should not be trapping students in a four-year timeline that drives up costs and delays careers. This plan will push for three-year degree options and accelerated pathways so students can enter the workforce sooner and avoid paying for unnecessary time in school. Students should have the choice to move faster, graduate sooner, and start building their careers. STOP TUITION FROM GOING UP This plan will freeze in-state tuition at California’s public colleges while forcing the system to cut waste and lower costs. TAKE CONTROL AND LEAD ON ACCOUNTABILITY As governor, Steve Hilton will use every tool available to force reform across California’s public colleges, working with his running mate for lieutenant governor, Gloria Romero. The lieutenant governor is the only elected official who serves on the governing boards of the University of California, the California State University system, and the California Community Colleges, and will show up, lead, and be a visible voice for affordability and accountability. SHOW FAMILIES WHERE THE MONEY GOES Clear campus-by-campus reporting, independent audits, and full program reviews will expose waste, ensure real value for taxpayers, and focus resources on programs that meet clear standards and lead to career-ready outcomes. This includes reviewing student housing to ensure it is used efficiently and prioritized for students who actually need it. MAKE COMMUNITY COLLEGE TRANSFER ACTUALLY WORK AND PUT CALIFORNIA STUDENTS FIRST Simpler transfer rules and stronger credit portability will ensure students do not lose time and money. Public universities should prioritize California students in admissions so those who grew up here have a fair shot at attending. That also means fixing the pipeline leading into college, so students are prepared when they arrive and not forced into remedial courses that add cost and delay. The administration will implement a “Kindergarten-to-College Pipeline Strategy” to ensure students are prepared at every stage. RESTORE STANDARDS AND ACCOUNTABILITY IN PUBLIC COLLEGES Public colleges should restore clear standards, real accountability, and a focus on results, not bureaucratic sprawl. That means prioritizing programs that lead to real careers and good jobs, enforcing merit-based decisions, protecting non-discrimination under Proposition 209, ensuring student safety during protests, and upholding fairness in women’s sports. CONCLUSION California’s public colleges should help young people get ahead. Instead, too many students are paying more, taking longer, and getting less. The Hilton-Romero administration will take on the bureaucracy, demand accountability, stop the cost spiral, modernize how students move through college, and make California’s public colleges affordable again. ← Back to all policies