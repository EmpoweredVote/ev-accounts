# Miami-Dade compass stances — resumable, last worked 2026-09-08

**This is the start of the stance program the Knight cities spec deferred** ("Out of scope: compass
stances. Stances are a separate program that follows this one, together with the deferred Nashville
stances" — `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md:6`).

## Where it stands

**Twelve rows live in Season 2**, seven of thirteen commissioners:

| topic | value | who |
| --- | --- | --- |
| `housing` | 4 | Bastien · Hardemon · McGhee · Regalado · Rodriguez |
| `growth-and-development` | 2 | Cohen Higgins · Steinberg · Garcia |
| `growth-and-development` | 4 | Rodriguez |
| `economic-development` | 3 | Cohen Higgins |
| `transportation-priorities` | 3 | Regalado |
| `residential-zoning` | 3 | Regalado |

⚠ **`housing` was re-opened 2026-09-08 for Steinberg, Garcia and Lopez — all three refusals CONFIRMED**,
this time with a missed-instrument control over their full unfiltered records rather than a lead
count. Steinberg has **zero** prime-sponsored housing instruments in 187 matters.

**Six whole-Board topic passes are done:** `housing` (123 matters), `transportation-priorities`
(83, 1 seated / 13 refused), `local-environment` (43, **0 seated** / 14 refused),
`residential-zoning` (49, 1 seated / 13 refused), `rent-regulation` (**0 seated** — the ladder does
not apply in Florida at all, see below) and `city-sanitation` (43, **0 seated** / 14 refused).

🔴 **PRICE THE YIELD BEFORE CHOOSING A TOPIC: six whole-Board passes have produced two rows.** That
is not pessimism, it is measured — see "this Board legislates by directive-and-report" below. Expect
the refusals file to be the main product, and treat a dense lead count as a poor predictor of a
seatable one.

Every refusal and its reason is in `backend/data/stance-research/2026-09-07-miamidade-refusals.md`.
**Read that before re-researching anybody.**

## The toolchain (all committed)

| script | answers |
| --- | --- |
| `miamidade-sponsorship-leads.mjs` | what has this commissioner put their name on? |
| `miamidade-voting-record.mjs` | how did they vote, per matter, per body (`--body=CDMZ\|HOUS\|TRNS\|IEIC\|RTRC`) |
| `miamidade-matter-detail.mjs` | **who actually owns it** — every sponsor with their role |
| `miamidade-axis-control.mjs` | 🟢 **what the pattern MISSED** — see below |
| `push-stance-csv.mjs` | season-aware upsert, `assertWritten` on both writes, `--dry-run` |

Run order: **axis test** → leads → detail → (votes where sponsorship under-determines) → read →
gate → push. Gate the CSV **before** pushing: `node scripts/audit-chair-evidence.mjs --csv <file>`.

🟢 **THE FULL INSTRUMENT TEXT IS THE STEP THAT KEEPS CHANGING ANSWERS.**
`matter.asp?matter=NNNNNN&file=true&fileAnalysis=false&yearFolder=YNNNN` links
`legistarfiles/Matters/Y<year>/<matter>.pdf` — recitals *and* operative sections.
⚠ That link **404s as HTTP 200 with 2,625 bytes of "Web Error" HTML** for some matters (`260174`,
`252269`, `261065` so far); always fetch a known-good one in the same run as a control.

## 🔴🔴 READ THE LADDER FROM THE SEASON PIN — `compass_stances` IS FROZEN AT v1

**`CA_0012` deliberately froze `compass_topics`' and `compass_stances`' text columns when content
versioning came in (ADR 0004).** The live wording lives in `inform.compass_stance_revisions`, keyed
by the `topic_revision_id` the season pins. **29 of the 60 topics in the open season disagree between
the two, 16 of them on all five rungs** — including `housing`, `growth-and-development`,
`economic-development`, `gun-policy` and all six `judicial-*`.

```sql
-- 🟢 CORRECT
SELECT sr.value, sr.text
  FROM inform.season_questions sq
  JOIN inform.seasons se ON se.id = sq.season_id AND se.status = 'open'
  JOIN inform.compass_topics t ON t.id = sq.topic_id AND t.topic_key = $1
  JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = sq.topic_revision_id
 ORDER BY sr.value;
-- 🔴 WRONG, and silent: SELECT value, text FROM inform.compass_stances WHERE topic_id = …
```

🟢 **Not a product defect** — every voter-facing read already uses the versioned source
(`compassService.ts`, `seasonCompositionService.ts`, `adminService.ts`). It is a **research-tooling
trap**: the frozen table returns a complete, plausible five-rung ladder on the right subject, with
`housing`'s *question text identical* while every rung differs. **A wrong ladder and a right ladder
look the same until you diff them.** Diff them.

## 🔴 TEST THE AXIS BEFORE STARTING A TOPIC — FOUR OF SIX PATTERNS WERE MIS-SPECIFIED

1. Read the five rungs. Write down the **one question** they all answer.
2. Read twenty lead titles. If they answer a *different* question, stop and retune first.
   Direction is rarely the problem; the axis usually is.
3. 🔴 **The leads file cannot tell you what the pattern MISSED** — it stores only what matched. Use
   **`node scripts/miamidade-axis-control.mjs --cache`** once, then `--grep=<regex>` or
   `--topic=<key>` to measure a retune offline against all 2,559 matters.
4. 🔴 The tool **refuses to report a zero** unless its positive control fires. Keep it that way.

**Scorecard so far:** `economic-development` carried bare `incentive` and CRA vocabulary ·
`housing` matched "SECTION 8-9 OF THE CODE" · `local-environment` asked about the health of the bay
and matched `RESILIENT AQUARIUM LLC` · `residential-zoning` matched a submerged-lands lease on
"LAND USE PLAN" and could not see the Rapid Transit Zone · `rent-regulation` was **23 of 23 false
positives**, all county property leases, all from bare `landlord`. 🟢 **`city-sanitation` was
SOUND and was left alone** — the first one that needed nothing, and that is a result too, not an
oversight. **Assume the pattern is wrong until measured, then say which way the measurement went.**

🟢 **MEASURE PER-ALTERNATIVE, NOT JUST OVERALL.** Running each alternative of `rent-regulation`
separately showed `landlord` scoring 30 and every other term scoring **0**, so the fix was one word
rather than a rewrite. `--grep` one alternative at a time; it takes a minute and it turns a guess
into a measurement.

## 🔴 THIS BOARD LEGISLATES BY DIRECTIVE-AND-REPORT, WHICH IS WHY THE YIELD IS LOW

Measured over the unfiltered corpus of **1,785 distinct matters**:

| shape | matters | share |
| --- | --- | --- |
| "DIRECTING THE COUNTY MAYOR…" | **363** | 20% |
| terminating in "PROVIDE A REPORT" / "REQUIRING A REPORT" | **119** | 6.7% |
| "URGING" the Legislature or Congress | **68** | 3.8% |

**One matter in five is a directive to the administration**, and a large share of those end in a
report that binds nobody; the urging resolutions bind nobody by construction. Under this program's
standard — **a study directive is not a chair** — a substantial fraction of what a commissioner
personally initiates cannot seat one, however on-topic it is.

That is the explanation for two rows from six passes, and it is a *prediction* as well as a
description. When scoping a topic, look at the shape of its leads, not just the count.

## 🔴🔴 A LADDER CAN BE LEGALLY UNAVAILABLE AT THIS LEVEL — AND THE FAILURE MODE IS A FALSE ROW

**Fla. Stat. § 125.0103(2)** forbids any Florida county from adopting or maintaining "any law,
ordinance, rule, or other measure that would have the effect of imposing controls on rents", and the
old housing-emergency exception is gone from the current text. So on `rent-regulation`:

- rungs 1 and 2 are things a commissioner **may not lawfully do**;
- rungs 3 and 4 both describe the preempted baseline and separate nobody;
- 🔴🔴 **rung 5 — "oppose rent control entirely" — is an accurate description of STATE LAW and of
  nobody's stated position.** Work backwards from the outcome and you seat all thirteen at 5, having
  recorded a preemption as thirteen personal beliefs.

**The danger of a mis-scoped ladder is not a blank spoke; it is a confident wrong row.** Before any
new topic, ask whether the rungs are things this officeholder can actually do — the per-rung scope
ruling in CLAUDE.md. ⚠ `rent-regulation` is NOT invalid in general: it carries `local` and `state`
roles and 237 answers exist elsewhere. The defect is jurisdictional, and `compass_topic_roles` has no
per-state dimension, so the refusals file is the only place this can be recorded.

## What the work taught, in priority order

1. 🔴 **A sponsor report is not proof of sponsorship.** Read `prime_sponsors` on the matter page.
   `261305` sits in Bastien's report and is Rodriguez's; `261104` sits in **nine** and is Rodriguez's.
2. 🔴 **`requester` is the discriminator, not volume.** A department item a member carried is weaker
   than one they originated. **Every EEL and wetlands item in the corpus is a DERM request.**
3. 🔴 **Read past the recitals to the operative section.** `26-51`'s recitals "support the safe use"
   of e-bikes; its operative §2-98.3(1) lets municipalities **restrict** them. `26-59` looked like
   deregulation and adds obligations. `252337` looked like tree policy and merely **spends** a fund.
4. 🔴 **A STUDY DIRECTIVE IS NOT A CHAIR, AND THE STANDARD MUST HOLD BOTH WAYS.** Gilbert refused on
   transportation, Bermudez refused on local-environment the same day on the same ground — despite
   being the only commissioner there with a coherent direction. Wanting a row is not a reason.
5. 🔴 **THE SAME INSTRUMENT CAN BE PROCEDURAL FOR ONE LADDER AND ON-AXIS FOR ANOTHER.** An RTZ parcel
   addition says nothing about transport investment and genuinely upzones the parcel. Tag both; judge
   separately.
6. 🔴 **Probe recency first.** Legistar answers HTTP 200 with JSON frozen at 2018.
7. 🔴 **A uniform answer is a broken detector until controlled.** ⚠ Sometimes it is real: the
   Transportation Committee is **one non-Yes vote in 435**, and the control is that the one was found.
8. 🔴 **A keyword can move a matter into the wrong topic and the write-up will inherit it.** Bare
   `surtax` put a transit resolution in the housing corpus and into Regalado's published housing prose.
9. 🔴 **THE COUNTY'S RECORD IS LIVE.** The same query over the same window returns **more** pairs
   later, as sponsors are added after filing. A run-to-run diff is not purely your own change.
10. **Never write an identifier you did not look up.** Five of seven source URLs from memory were wrong.
11. **Which report fits depends on the topic.** Growth decisions are *applications* nobody sponsors;
    transportation, environment and zoning policy is *initiated*. Decide before paying for a report.
12. 🔴🔴 **A CITED-ID CONTROL RUNS ONE DIRECTION. RUN IT BOTH WAYS.** "Every cited id resolves,
    names the instrument the prose names, and carries the right prime sponsor" is *sources → reality*.
    It cannot see an instrument the prose **names** that no source points at. Regalado's two rows pass
    the one-way control on all five citations — and **both rows named an instrument nothing cited**:
    `residential-zoning` asserted ordinance 26-47 (`261065`), fixed by `CC_0081`; `transportation-priorities`
    asserted "the state grant agreements funding bus operations and a new park-and-ride facility on the
    South Dade Transitway" — R-279-25 (`250457`), R-210-26 (`260354`) and R-267-26 (`260527`), all three
    sole-prime hers and all `requester = Transportation and Public Works` — fixed by `CC_0082`. Both rows
    now cite every instrument they name. **List every instrument the reasoning names, then check that
    list against `sources`.** `reasoning` is voter-facing: an uncited named instrument is a claim
    rendered beside links that do not carry it.
    ⚠ **CITE THE CLAIM, NOT THE THEME.** R-281-25 (`250461`) is also hers, also adopted, also on that
    corridor — and funds *enhancements to existing stops*, not "a new park-and-ride facility". It was
    deliberately left out. Padding a source list with adjacent instruments is how it stops meaning
    anything.
    🔴🔴 **MEASURED ACROSS A WHOLE TOPIC 2026-09-09: 3 OF 5 `housing` ROWS WERE SHORT, 13 INSTRUMENTS
    IN ALL.** Hardemon named 9 and cited 3; Bastien 8 and 3; McGhee 5 and 3. Rodriguez (1/1) and
    Regalado (3/3) were complete. All 13 were verified live — every one Adopted, every one SOLE prime
    sponsor of the row's subject — and cited by `CC_0083`, which also fixed McGhee's array into prose
    order. **The one-way control passed 13 of 13 on the same rows**, so it is not a substitute.
    → So expect roughly half the rows written before 2026-09-08 to name something uncited. Sweep a
    topic at a time, oldest pass first, and read the prose for instrument names rather than trusting
    the citation count.
    🟢 **The lookup route, when a named instrument is not in the corpus:** run
    `miamidade-sponsorship-leads.mjs --name="<member>"` and grep its report for the reference number —
    that is how R-664-26/R-665-26/R-497-25/R-498-25 were found (`261171`, `261172`, `250903`, `250906`).
    Then open every matter before citing it; the report is a lead, not proof.
    ✅ **SWEEP CLOSED 2026-09-09. All twelve Season 2 rows checked both ways; SIX carried the defect.**
    residential-zoning 1/1 (`CC_0081`) · transportation-priorities 1/1 (`CC_0082`) · housing 3 of 5
    (`CC_0083`) · growth-and-development 1 of 4 (`CC_0084`, Cohen Higgins: R-1173-25 `252187` and
    R-337-26 `260291`, both sole-prime hers, both "community-specific thematic zoning district") ·
    economic-development 0 of 1. **26 of 26 citations passed the one-way control throughout.**
    Rows now carry 52 citations, up from 30. 🔴 **Half a corpus is the base rate for prose written
    before the control existed — assume it for Nashville and any other pre-2026-09-08 pass.**

## 🔴 OPEN, NEEDS A HUMAN: four rows describe the LU-8H vote more precisely than the record does

Found while reading `241888` in full to check the vote claims. **Not a citation gap and not fixable in
a `sources` migration** — it is voter-facing prose, so it wants a reviewed edit.

The page's legislative history for 6/26/2025 records, in order: Chairman Rodriguez moved to **reject
staff's recommendation and approve the 1:1 ratio**; that motion **FAILED 6-4** (Steinberg, Cohen
Higgins, Garcia and McGhee voted "no"; Gonzalez, Hardemon and Higgins absent); the County Attorney
advised **7 votes were needed**; Garcia moved to reconsider, **passed 10-0**; Rodriguez restated the
motion; and then "the Board voted to reject staff's recommendation and approve the application as
presented" — **with no tally recorded at all.**

- **Rodriguez's row says "The Board adopted it 7 votes to 3."** No source shows that tally. 7 is the
  number of votes the County Attorney said were REQUIRED, which is the likeliest origin of the error.
- **Cohen Higgins, Steinberg and Garcia's rows say each "voted No" and the Board "adopted it anyway."**
  Their No is real and points the right way — against loosening LU-8H — but it is on the failed
  pre-reconsideration motion. The adoption vote is untallied, so **no source shows how any member voted
  on adoption.**

⚠ **No chair moves either way**: Rodriguez's 4 rests on sponsoring R-44-24, R-1036-24 and 25-59, and
the other three rest on the No vote plus their own resolutions. The fix is wording, not evidence.
✅ **FIXED 2026-09-09 by `CC_0087`** (approved wording: minimal correction). Rodriguez's row now says
the Board adopted it as filed "with no tally recorded for that vote"; the other three say each voted No
"on the motion to reject staff's recommendation and approve the 1-to-1 ratio, which failed 6 votes to 4".
Chairs and sources untouched. The post-verify asserts that **reversing the edit reproduces the original
byte for byte**, which is the only check that proves nothing else in 1,200 words of prose moved.
🔴 **AND IT IS THE RECITAL/OPERATIVE RULE IN A NEW COSTUME:** a narrative summary of a meeting is not
the vote record, and the tally next to the motion you are reading may belong to a different motion.

### ▶️ OPEN RE-AUDIT: does Garcia's `growth-and-development` chair 2 still fit?

Raised by `CC_0087`, decided by nobody yet. The 6/26/2025 record shows Garcia voted No on the motion to
approve the 1-to-1 ratio **and then moved to reconsider it** — his motion passed 10-0, and the Board went
on to adopt the amendment. His row now states this.

- **For keeping 2:** he prime-sponsored nothing that loosens LU-8H, and co-sponsored R-191-26 (opposing
  HB 399) and R-678-26 (UDB text amendments), both boundary-protective and both cited. Under most rules
  only a member on the PREVAILING side may move to reconsider, and his side prevailed when the motion
  failed — so the motion may be procedural courtesy after the County Attorney corrected the vote
  threshold, and say nothing about his position.
- **Against:** the reconsideration is what let the amendment pass, and no source records how he voted on
  the untallied final vote. A reader could reasonably read the sequence either way.
- 🔴 **The honest tie-breaker is NOT "the least extreme option"** — that is the signal the row is
  under-evidenced. If the sequence genuinely under-determines the chair, the answer is a blank spoke,
  not a chair chosen for comfort.
- **What would settle it:** the minutes or video of the final vote, if any record of the tally exists;
  or one substantive own instrument of his on the boundary.

## Cheapest next steps

- **`jail-capacity` (13) · `climate-change` (9) · `homelessness-response` (9) · `civil-rights` (5)
  · `homelessness` (5)** — all thin. Axis-test each before reading; on current form roughly two of
  three patterns are mis-specified, and a thin count is as likely to be a broken detector as a
  quiet record.
- ⚠ **Before starting any of them, read the directive-and-report finding below.** A topic whose
  leads are mostly "DIRECTING THE COUNTY MAYOR … AND PROVIDE A REPORT" will refuse, however dense.
- ✅ **`city-sanitation` is CLOSED** — 0 seated. Its pattern is sound; do not retune it.
- ✅ **`rent-regulation` is CLOSED and should not be re-attempted in Florida** — state preemption,
  above. Its pattern is fixed (30 leads → 0, which is the true answer).
- **Steinberg, Garcia, Lopez on housing** — each needs one substantive own instrument.
- **Lopez on residential-zoning** — needs a subzone she creates with standards, not parcel additions.
- **Gilbert on transportation** — needs a funding mechanism he proposes, not a study of possible ones.
- **Bermudez on local-environment** — needs `250607` or `261179` adopted, or Board action on the
  mitigation-bank report.
- ⚠ **`growth-and-development` carries CRA administration**; splitting CRA *creation* from CRA
  *housekeeping* would clean up ~14 of Cohen Higgins' 21.
- ⚠ **Nothing matches bay water quality, septic-to-sewer or sea-level-rise resilience any more.**
  Deliberate — no ladder asks. Whoever reads the `climate-change` ladder should decide; **do not add
  them back to `local-environment`.**
- 🔴 **Eileen Higgins is prime sponsor of the two most on-axis zoning policy instruments** (`250899`,
  `251728`) **and has left the Board.** Sitting members are co-sponsors only. If former members are
  ever in scope, that is where to start.

## Cautions for whoever resumes

- Season 2 is open; Season 1 is closed. Writes land in Season 2 via `seasonService`.
- **Every pre-existing Season 2 row has `editor_id = NULL`**; these twelve are attributed to
  `chris@empowered.vote` (`4e6dde8f-2bd0-4054-824f-4164744165ea`). Pass `EV_EDITOR_ID`. **Look it up
  from an existing row; do not retype it.**
- 🟢 **The leads cache was regenerated 2026-09-08** over 2025-01-01 → 2026-09-05 and agrees with the
  patterns. **`git diff` the patterns file against the cache's commit before trusting a lead count.**
- 🔴 **RE-MEASURE A BASELINE BEFORE SPENDING ON IT.** "Hardemon growth, 21 leads" was Cohen Higgins'
  (he has 5). `local-environment` was chosen because Steinberg had "16 leads" — all 16 off-axis.
- **An instrument may be cited on two ladders** if it answers both questions and each row argues its
  own (R-551-26 is on transportation and zoning). That is not the "one source → two chairs" case,
  which is about two chairs on ONE ladder.
- Research CSVs are gitignored; the DB rows and their `reasoning` are the durable record. The
  machine-local jurisdiction file is `backend/data/stance-research/2026-09-07-miamidade.csv` and
  mirrors all twelve rows — **update a row in place, never append a duplicate.**
- The county serves **U+FFFD** where quotation marks were. Unrecoverable; repair at the point of
  quoting, never in bulk.
- Worktree is recreated per session. 2026-09-08 used `feat/miamidade-stances-2` (PR #415) off master.
  Never work in `C:/EV-Accounts`.
