# Miami-Dade compass stances — resumable, last worked 2026-09-08

**This is the start of the stance program the Knight cities spec deferred** ("Out of scope: compass
stances. Stances are a separate program that follows this one, together with the deferred Nashville
stances" — `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md:6`).

## Where it stands

**Thirteen rows live in Season 2** (12 + `jail-capacity` Rodriguez at 2, added 2026-09-09), seven of thirteen commissioners:

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

**Eleven whole-Board topic passes are done:** `housing` (123 matters), `transportation-priorities`
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

### ✅ CLOSED 2026-09-09: Garcia's `growth-and-development` chair 2 STANDS — no row moved

Raised by `CC_0087`. Settled from the primary record (`241888`, `260879`, each fetched with a
Web-Error control in the same run), not from the narrative summary above.

🔴🔴 **THE PREMISE WAS WRONG: THIS WAS NEVER A GARCIA-SPECIFIC QUESTION.** Garcia and Steinberg cite the
**identical three sources** — `241888`, `260228`, `260967`. Only the reconsideration could separate them,
and the record says it cannot:

> "Senator Garcia moved to reconsider the foregoing application. **This motion was seconded by
> Commissioner Steinberg**; and upon being put to a vote, **passed 10-0**."

**Steinberg seconded the very act the re-audit treated as Garcia's differentiator**, and all four No
voters sit inside the 10-0. Were it a position rather than a procedure, it would unseat Cohen Higgins and
Steinberg on the same record. It followed ACA Schwaderer Raurell's advice that **7 votes were needed**, so
the 6-4 was a threshold artifact, not a defeat on the merits. **A unanimous procedural motion states
nobody's position.** The final adoption is still untallied — "the Board voted to reject staff's
recommendation and approve the application as presented", no numbers, no names. `CC_0087`'s wording stands.

#### 🔴🔴 AND THE AXIS CONTROL OVERTURNED THE FIRST ANSWER — HE DOES HAVE OWN INSTRUMENTS

This section first said "no own instrument exists either way", read off his **6 pattern leads**. That was a
detector reporting nothing found. Grepping all 2,560 cached rows for
`URBAN DEVELOPMENT BOUNDARY|UDB|LU-8H|CDMP` returned 17 matters, 8 of them Garcia's — and **five the growth
pattern never surfaced.** Three are his own:

| matter | ref | status | role | what it does |
| --- | --- | --- | --- | --- |
| `251903` | — | Amended | **Prime** | CDMP amendment: flexibility in the **minimum acreage requirement for commercial vehicle storage** |
| `252447` | — | In Draft | **Prime** | same initiative, original item |
| `260879` | — | **Failed** 7/21/2026 | **Prime** | same, plus a report on vacant county parcels and a limited enforcement stay |
| `251393` | R-687-25 | Adopted | Co-Sponsor | container stacking with commercial vehicle storage (Gilbert Prime) |
| `261141` | — | Before the Board | Co-Sponsor | CDMP allowances inside urbanized areas (Gonzalez Prime) |

**They do not move the chair, and the reason is the per-rung scope rule, not their outcome.** `260879`'s
full page mentions the Urban Development Boundary **zero times** — no `UDB`, no `LU-8H`, no "outside the".
It is where trucks may be parked. The pinned rung 2 asks whether growth waits for **infrastructure
capacity**; a sectoral acreage standard does not answer that question either way. Off-axis evidence must
not dilute on-axis evidence — that is what "scope is a per-rung question" means.

⚠ **This is NOT the Regalado case.** Hers was mixed **on the same axis** — voted Yes to loosen the UDB and
prime-sponsored closing a route around it — so it pointed at two rungs and pinned neither. Garcia is
boundary-protective on-axis and deregulatory off-axis. Different test, different answer.
⚠ Note also that all three of his own are unadopted, and `260879` is partly a **report directive** — either
would be enough on its own under this program's standard.

**So the chair rests where it did:** a recorded No against lowering LU-8H's jobs-to-housing ratio and
first-phase density — *capacity tests, rung 2's mechanism verbatim* — plus two boundary-protective
co-sponsorships. Rung 1 stays out on the absence of any cap or referendum instrument. **No migration.**

⚠ **What would reopen it:** a source recording the final tally, or one substantive own instrument of his
**on the boundary**. Neither exists today.

#### ✅ PATTERN RETUNED 2026-09-09: `growth-and-development` was wrong in BOTH directions

Measured per-alternative on the unfiltered 2,560-row sweep — the only way the shape was visible:

| alternative | leads / matters |
| --- | --- |
| `community redevelopment` | **60 / 54** — the flood |
| `CRA` | **41 / 35** — the flood |
| `urban development boundary` | 12 / 6 |
| `UDB` · `impact fee` · `moratorium` | 3/1 · 3/3 · 2/2 |
| `concurrency` · `infrastructure capacity` · `development order` · `planned development` · `growth management` · `TIF` | **all zero** |

**84 leads / 68 matters → 61 / 42.** 43 housekeeping items out (CRA budgets, appointments, chair
designations, Naranja Lakes potholes and landscaping); 16 real ones in — the five CDMP amendments,
plus `250695` PROHIBIT THE CREATION OF COMMUNITY REDEVELOPMENT and `251426` CREATING THE EAR TASK FORCE.

- 🟢 **The zero-scoring alternatives were KEPT.** `concurrency` and `infrastructure capacity` are rung
  2's own words. A zero costs no false positives; deleting it would be tidying, not tuning.
- 🔴 **The carve-out is scoped to the CRA branch, and that is load bearing.** Applied globally it
  suppressed `252187` and `260291` — **Cohen Higgins' two cited sources for her seated chair 2.** A
  carve-out that reaches the on-axis branch takes live rows with it.
- 🔴🔴 **TWO SUBSTRING TRAPS, FOUND ONLY BY AUDITING EACH CARVE-OUT TERM AGAINST REAL TEXT.** `vice`
  matched "business support ser**VICE**s" and wrongly dropped `250514`; `designat` matched
  "co**DESIGNAT**ion" street namings. Both removed — `chair` alone still excludes the chair and
  vice-chair designations. **A bare substring is not a word.**
- 🔴 **The old pattern also missed `250695` because it asked for `community redevelopment (agency|area)`
  and the county wrote "AGENC**IES**".** The bare phrase now matches.
- ⚠ **A CRA annual budget now matches NOTHING, deliberately.** `economic-development`'s note says
  redevelopment financing "rides on growth-and-development" — financing **policy** still does, and that
  is pinned by a test. A budget approval evidences no rung on any ladder.
- ⚠ **Residual, accepted:** the added CDMP items include truck-parking and vertical-farming amendments
  that are off-axis for this ladder. Correct **leads**, wrong **chairs** — read past them.
- 🔴 **`241888` IS NOT IN THE LEADS CORPUS AT ALL.** The sponsor-report cache is windowed and ordinance
  25-59 falls outside it, so no pattern can reach the county's central growth instrument. **A researcher
  working from leads alone would never see LU-8H.**

Four tests added in `miamidade-sponsorship-parse.test.ts`; **three were watched failing against the old
pattern first.** The fourth is a preservation guard and passes under both by design.

## Cheapest next steps

- ✅ **`jail-capacity` RETUNED 2026-09-09 — AND IT WAS NEVER THIN.** "13 leads" was a broken
  detector, not a quiet record: **13 / 8 → 44 / 20.** Two of the old eight matters were substring
  artefacts (bare `bail` matched "**BAIL**ES COMMONS" and "JUDGE MELVIA **BAIL**EY-GREEN TERRACE"),
  and `corrections (facility|department)` scored **zero** while bare `corrections` scored 5 — the
  county writes "Corrections and Rehabilitation".
  🟢 **What it could not see is the heart of the topic:** the **Mental Health Center** cluster
  (`261104` `261093` `261088` `260425` `260201` `250513` `261006`), **MISDEMEANOR DIVERSION**
  (`250837` `250794` `252312`) and `250119` SECOND CHANCE ACT COMMUNITY-BASED REENTRY. Rung 1 is
  *"redirecting incarceration funding into community-based mental health … to shrink the jail
  system"* — the pattern was blind to its own rung 1.
  🔴🔴 **`consent decree` MEASURED AND REJECTED: 40 / 39, every one a WATER AND SEWER contract**
  under the WASD decree; `consent decree AND (jail|correction)` returns **zero**. Miami-Dade's jail
  decree is real but this corpus does not name it. 🔴 **Bare `diversion` rejected too** — 34/13, the
  extras are WASTE diversion. Qualified instead.
  ✅ **READ 2026-09-09 — 20 matters, 1 seated: Anthony Rodriguez at 2** on R-558-26 (`261104`, the
  Mental Health Center as a Designated Receiving System facility) and R-556-26 (`261019`, competency
  restoration through MDCR), both adopted, both his own initiative, neither adding capacity.
  ⚠ **A ONE-INSTRUMENT CHAIR, said plainly in the refusals file** — `261019` reads as rung 3 as easily
  as rung 2, and only `261104` reads one way.
  🔴 **The most tempting row in the corpus is a REFUSAL:** R-328-23 (`260843`) "strongly opposing" any
  pretrial-release reform is prime-sponsored by **Cabrera, who has left the Board**, and co-sponsored by
  **Bermudez, Garcia and Gonzalez**. It binds nobody and gives direction without magnitude — it argues
  against rung 2 but reaches neither 4 nor 5. Do not re-research it as new.
  ⚠ Rung 2 names **bail reform, which a county commission cannot do**. The rung survives here on its
  other two mechanisms; a row resting on the bail clause alone would be the per-rung scope error.
  ⚠ The frozen/pinned ladders **AGREE** for this topic — the `CA_0012` trap is per-topic, not universal.
- ✅ **`climate-change` CLOSED 2026-09-09 — 6 matters read, 0 seated.** 🔴🔴 **The pattern was aimed at
  the FROZEN ladder.** Frozen asks about climate policy generally ("declare a climate emergency", "phase
  out fossil fuels"); the **pinned** ladder asks *"How much should government do to expand clean
  energy?"* — `climate|greenhouse gas|carbon` is the frozen question's vocabulary. **Diff the ladders
  before writing a PATTERN, not just before writing a row.**
  🔴🔴 **Fla. Stat. § 366.032 makes rung 1 largely unavailable and rung 4 the STATE'S position** — a
  county may not restrict the fuel sources a utility supplies; the carve-out reaches only a government
  that owns its own utility (Miami-Dade does not); and any such policy predating 1 Jul 2021 is **void**.
  Seating anyone at 4 from an empty record publishes a preemption as a belief — the `rent-regulation`
  failure in a new topic. Rungs 2 and 3 (investment, permitting) are real county levers; nobody used them.
  ⚠ **This settles the `local-environment` open question: bay water quality, septic-to-sewer and
  sea-level-rise resilience DO NOT belong here.** The pinned ladder is about expanding clean energy, not
  adaptation. `resilien` returns 16/14 and answers none of it. **No open-season ladder asks it.**
  🟢 **This time the thin record is REAL** — but only provable after 25 terms were measured. `energy`
  (16/11) is waste-to-energy siting and `FPL` (18/18) is utility easements; both rejected. Two more
  semantic traps found: `carbon` matched **CALCIUM CARBONATE**, `interconnection` matched **EMERGENCY
  WATER INTERCONNECTION**.
- ✅ **`homelessness-response` · `homelessness` · `civil-rights` ALL CLOSED 2026-09-09 — 17 matters
  read, 0 seated.** All three pinned ladders disagree with the frozen table.
  - **`homelessness-response` 9/9 → 23/15.** 🔴🔴 **Bastien is prime on 11 of 14 and that is her
    Homeless Trust role, not a position** — 9 carry `requester = Miami-Dade Homeless Trust`. Her own
    items are a **$62.5M HUD CoC grant acceptance** and two **urging** resolutions. ⚠ **Rungs 1 and 2
    cannot be separated here**: the 1% food and beverage tax already IS "dedicated, permanent public
    funding", and `251914` spends $21.1M/yr FY26-28 "with targeted increases" — rung 1's mechanism
    doing rung 2's job. Two adjacent chairs ⇒ refuse.
  - **`homelessness` — 🔴🔴 Fla. Stat. § 125.0231 writes most of the ladder.** A county "may not
    authorize or otherwise allow" public camping; a designated site needs **DCF certification** proving
    insufficient shelter beds. **Rungs 1 and 2 are unavailable; rung 4 is what the state REQUIRES.**
    Third instance of this failure mode in one day. Whole corpus = one Bastien plan-and-report item
    filed twice, never adopted. Pattern measured and **deliberately left alone**.
  - **`civil-rights` 5/4 → 2/1 — 🔴🔴 three of the old four were PROPER NOUNS.** `equity` matched
    **"ELITE EQUITY"** (a developer) twice and `DBE` matched **"DBE MISS USA, LLC"** (a pageant).
    **A word boundary does not save you from a company name.** Every other term scored zero. The one
    real item — Garcia urging a veto of the anti-DEI bill SB 1134 — is a refusal: urging binds nobody,
    and it gives direction without magnitude. ⚠ Rung 4 names **federal** enforcement, unavailable here.
- ▶️ **NO CHEAP TOPICS REMAIN.** Every topic named in this list has now been measured and read.
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
