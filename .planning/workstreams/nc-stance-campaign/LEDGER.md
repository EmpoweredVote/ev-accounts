# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|
| S05 | 2026-08-25 | NC Senate — correct sponsor lists | 3 | **3** | 0 | `2026-08-25-nc-senate05.csv` | `written-senate05.json` |
| S04 | 2026-08-25 | NC Senate — Republican bills | 4 | **4** | 0 | `2026-08-25-nc-senate04.csv` | `written-senate04.json` |
| S03 | 2026-08-25 | NC Senate — housing + AI companions | 12 | **12** | 0 | `2026-08-25-nc-senate03.csv` | `written-senate03.json` |
| S02 | 2026-08-25 | NC Senate — housing companions | 3 | **3** | 0 | `2026-08-25-nc-senate02.csv` | `written-senate02.json` |
| S01 | 2026-08-25 | NC Senate — 3 chair-verified bills across the chamber | 50 | **22** | 0 | `2026-08-25-nc-senate01.csv` | `written-senate01.json` |
| 12 | 2026-08-25 | NC House districts 111-120 | 10 | **16** | 0 | `2026-08-25-nc-batch12.csv` | `written-batch12.json` |
| 11 | 2026-08-25 | NC House districts 101-110 | 10 | **14** | 0 | `2026-08-25-nc-batch11.csv` | `written-batch11.json` |
| 10 | 2026-08-24 | NC House districts 91-100 | 10 | **15** | 0 | `2026-08-24-nc-batch10.csv` | `written-batch10.json` |
| 09 | 2026-08-24 | NC House districts 81-90 (+3 backfills) | 10 | **11** | 0 | `2026-08-24-nc-batch09.csv` | `written-batch09.json` |
| 08 | 2026-08-24 | NC House districts 71-80 | 10 | **14** | 0 | `2026-08-24-nc-batch08.csv` | `written-batch08.json` |
| 07 | 2026-08-24 | NC House districts 61-70 (+1 backfill) | 10 | **13** | 0 | `2026-08-24-nc-batch07.csv` | `written-batch07.json` |
| 06 | 2026-08-24 | NC House districts 51-60 | 10 | **18** | 0 | `2026-08-24-nc-batch06.csv` | `written-batch06.json` |
| 05 | 2026-08-24 | NC House districts 41-50 | 10 | **20** | 0 | `2026-08-24-nc-batch05.csv` | `written-batch05.json` |
| 04 | 2026-08-24 | NC House districts 31-40 | 10 | **26** | 0 | `2026-08-24-nc-batch04.csv` | `written-batch04.json` |
| 03 | 2026-08-24 | NC House districts 21-30 (+3 backfills) | 10 | **17** | 0 | `2026-08-24-nc-batch03.csv` | `written-batch03.json` |
| 02 | 2026-08-24 | NC House districts 11-20 | 10 | **10** | 0 | `2026-08-24-nc-batch02.csv` | `written-batch02.json` |
| 01 | 2026-08-24 | NC House districts 1-10 | 10 | **8** | 0 | `2026-08-24-nc-batch01.csv` | `written-batch01.json` |
| pilot | 2026-08-24 | Ager (HD 114) · Mayfield (SD 49) · Kopac (Durham W1) | 3 | **8** | 5 parked, 0 inserted | `2026-08-24-nc-pilot-approved.csv` | `written-pilot.json` |

## Pre-campaign baselines (measured 2026-08-24, before any batch was pushed)

Task 6 compares the end state against these. Measure them again at close-out, not the delta.

| Measure | Baseline |
|---|---|
| `inform.politician_answers` rows, all corpora | 32,887 |
| `inform.politician_context` rows, all corpora | 33,541 |
| Context rows with no matching answer (orphan context) | **654** |
| Answer rows for anyone holding an NC seat | 326 |
| Answer rows for the 202 people in this campaign | 0 |

The orphan-context number is the one that must not grow. A context row without an answer is an
unpublished claim: it renders the moment someone writes an answer for that pair.

## Batch notes — pilot (2026-08-24)

**38 rows researched, 8 pushed.** Every instrument behind the 8 was opened and read on ncleg.gov
before the write; the reasoning was rewritten to name the bill in North Carolina's own style.

Held or dropped, and why — these are the shapes to expect for the other 199 people:

| Shape | Example | Disposition |
|---|---|---|
| Bill misdescribed | `school-vouchers` cited H87 as a voucher bill. H87 is a cell-phone-free education bill; the 114-3 vote was on cell phones. | dropped |
| Names no instrument | Mayfield `immigration` cited a campaign page describing "bipartisan legislation" with no number. | dropped |
| Direction, not magnitude | Mayfield `trans-athletes`: a No vote on a ban rules out chair 4 but cannot separate chair 1 from chair 2. | held |
| Bare roll-call vote | Mayfield `climate-change`: H951 passed the Senate 42-7. A vote 42 of 49 senators cast discriminates no personal chair. | held |
| Two adjacent chairs fit | Mayfield `childcare`: S412 raises subsidy rates but states no eligibility band, so chairs 2 and 3 both fit. | held |
| Aggregated across bills | Mayfield `housing` rested on S495 plus two unverified funding bills. S495 alone is a pure zoning mandate with no money, which reads closer to chair 4. | held |
| Chair is federal in scope | `same-sex-marriage` chair 1 requires recognition by all states and full federal benefits. No state bill can evidence either clause. | held, logged for season 2 |
| Promise, not instrument | All 7 of Kopac's rows rested on a campaign platform page. | held — he seated 0 |

Ager's `housing` survived the same test Mayfield's failed: House Bill 1056 is a **single** instrument
carrying both the deregulation and the $40 million subsidy, so chair 3 is the only chair that fits
both halves. Chair 4 has no room for the money.

**Two ladder defects for the ADR 0004 revision queue**, not workarounds for this campaign:
`medicare/aid` chair 2 reads "lower Medicare age to 55 and expand Medicaid significantly", and
`same-sex-marriage` chairs 1 and 2 are written at federal scope. A state legislator can never
evidence either fully, so those spokes are unreachable by construction for all 170.

## Batch notes — batch 01, NC House districts 1-10 (2026-08-24)

**8 rows across 6 people. Four members seated nothing.** Researched inline, primary sponsorships
first, every cited bill opened and read.

| District | Member | Rows |
|---|---|---|
| 1 | Edward C. Goodwin | 0 — veterans and commemorative bills only |
| 2 | B. Ray Jeffers | redistricting 1 |
| 3 | Steve Tyson | data-centers 2 |
| 4 | Jimmy Dixon | 0 — agriculture bills; a Medicaid rebase is routine funding, not a chair |
| 5 | Bill Ward | **0 — blanked by his own conflict** |
| 6 | Joseph Pike | data-centers 1 |
| 7 | Matthew Winslow | housing 4 |
| 8 | Gloristine Brown | childcare 2 · housing 3 · redistricting 1 |
| 9 | Timothy Reeder, MD | 0 |
| 10 | John R. Bell, IV | housing 3 |

### The Ward conflict, and why it matters

Ward is a **primary sponsor of both** House Bill 1189, which imposes a datacenter permit moratorium
(chair 1), **and** House Bill 638, which instead makes data centers pay for their own dispatchable
power (chair 2). Two adjacent chairs, both his own bills. His `data-centers` spoke is blank.

The same check cleared three others: Tyson is not on House Bill 1189, Pike is not on House Bill 638,
and Ager (pilot) is a cosponsor of 1189 only. **Check every member against every instrument on the
topic before seating, not just the one you found first.**

### Housing 3 versus housing 4 is a real distinction, not a partisan one

Ager, Gloristine Brown and Bell all sit at chair 3; Winslow sits at chair 4. The discriminator is
whether public money is present. Ager's House Bill 1056 pairs deregulation with a $40 million
subsidy; Brown pairs House Bill 404's Housing Trust Fund money with House Bill 626's easier
permitting; Bell's House Bill 1072 is $50 million in below-market loans. Winslow's two bills — House
Bill 765 and House Bill 627 — spend nothing and work purely by removing local rules, which is what
chair 4 says. **Bell is the House Majority Leader and lands on the same chair as two Democrats.**
That is the compass working as designed.

### 🔴 A SHORT TITLE IS NOT EVIDENCE. Five bills in ten members contradicted their own titles

- `Beyond The Choice Act` (H422) — veterans' tuition, not abortion
- `Expedited Removal of Unauthorized Persons` (H96) — amends the trespass statutes; squatters, not immigration
- `Energy Security Act of 2025` (H73) — physical security at electrical substations
- `Save the American Dream Act` (H765) — a local development-regulation omnibus
- `Limit Use of AI Medicaid/Commercial Insurance` (H565) — the text returned an organ-donor tax provision

**Cross-check by sponsor list.** When a bill's text and its title disagree, compare the sponsors on
the text page against the sponsors on the lookup page. If they match, the text is the right bill and
the title is just branding (H765). If it cannot be resolved, leave the spoke blank — H565 would have
been the campaign's only `ai-regulation` row and it is not worth seating on a self-contradicting
source.

### 🔴 Fourth ladder defect: voting-rights is asymmetric

Tyson is primary sponsor of House Bill 66, which shortens early voting by about a week. Chair 2
explicitly names *expanding* early voting periods, but **no chair names reducing them** — the
restrictive chairs are about photo ID, voter-roll maintenance and mail-in voting, none of which the
bill touches. So the ladder will seat members who expand early voting and blank members who restrict
it, on the same axis. That is a coverage bias built into the scale, and it belongs in the ADR 0004
revision queue with the `medicare/aid` and `same-sex-marriage` scope defects.

## Batch notes — batch 02, NC House districts 11-20 (2026-08-24)

**10 rows across 4 people. Six members seated nothing.**

| District | Member | Rows |
|---|---|---|
| 11 | Allison A. Dahle | redistricting 1 · civil-rights 2 · housing 3 |
| 12 | Chris Humphrey | housing 3 |
| 13 | Celeste C. Cairns | 0 |
| 14 | Wyatt Gable | 0 |
| 15 | Phil Shepard | 0 |
| 16 | Carson Smith | 0 |
| 17 | Frank Iler | 0 |
| 18 | Deb Butler | redistricting 1 · civil-rights 2 · abortion 2 · campaign-finance 2 · data-centers 1 |
| 19 | Charles W. Miller | 0 |
| 20 | Ted Davis, Jr. | ai-regulation 3 |

**First `ai-regulation` row in the campaign.** House Bill 375 requires AI-generated political content
to carry disclosure and embedded provenance and makes creators liable for resulting harm, with
criminal penalties and damages to $10,000 — chair 3. It requires no safety testing and bans no
category of use, which excludes chair 4. Remember this ladder runs the opposite way from most:
chair 1 is the *least* oversight.

### 🔴 CORRECTION to batch 01's "a short title is not evidence"

The batch 01 note listed five bills as contradicting their titles. That is too strong for two of
them, and the real situation is worse in a different way:

- **H422 and H96 are settled.** Both were judged from BillLookUp *metadata* — the statute chapters
  and keywords — which is independent of the title. `Beyond The Choice Act` amends Chapter 116
  (colleges and universities); `Expedited Removal of Unauthorized Persons` amends Chapter 14
  (trespass). Those conclusions stand.
- **H765 is settled.** The sponsors on the text page matched the lookup page, and the content matches
  the title's evident purpose. `Save the American Dream Act` genuinely is a development-deregulation
  omnibus.
- **H565 and H727 are UNRESOLVED, and both are blank because of it.** The member list and the lookup
  page agree that H565 is `Limit Use of AI Medicaid/Commercial Insurance` (keyword ARTIFICIAL
  INTELLIGENCE, amending Chapters 108C, 58 and 90) and that H727 is `Limit Medicaid Reimb. for
  Facility Fees`. But **editions 1 and 2 of both, served from `/Sessions/2025/Bills/House/HTML/`,
  are different subjects entirely** — organ-donor tax enrolment and marriage-and-family-therapist
  licensure — with the correct sponsors attached. A gut-and-replace would explain it, but the later
  edition still shows the old subject, so that theory does not hold either.

**The rule: when the served text and the title disagree and cannot be reconciled, leave the spoke
blank.** H565 would have seated `ai-regulation` for Reeder (district 9), Shepard (district 15),
Potts and Huneycutt. It is worth resolving properly — by reading the PDF rather than the HTML — but
not worth guessing.

### Refusals worth recording

- **House Bill 282** (Butler, primary) changes bike and pedestrian funding from "shall not provide"
  to "may provide". Someone who wants to *prioritise* walking and transit (chair 1) and someone who
  wants it *selectively* (chair 3) would both file it. Two chairs fit, so it seats nothing.
- **House Bill 318** (Carson Smith, primary) creates a judicial hold process for ICE detainers with a
  48-hour cap. It does not decide *who* is deported, which is what the `deportation` ladder asks.
- **House Bill 799** (Gable, primary) bars state funds for DEI programs, but by its own terms does not
  reach voluntary initiatives or admissions. Chair 5 requires eliminating affirmative action **and
  all** race-based government programs; chair 4 is about limiting *federal* enforcement. Neither is
  named.

### 🔴 Fifth ladder observation: `civil-rights` is asymmetric the same way `voting-rights` is

Chair 2 is reachable by a state bill — Equality for All seats it cleanly, twice in this batch. But
chair 4 is written about **federal** enforcement, which no state legislator can do, and chair 5
demands **all** race-based programs be eliminated, which a partial DEI funding ban does not achieve.
So the restrictive half of this axis is close to unreachable for the people we are scoring, exactly
like early voting on `voting-rights`. Both belong in the ADR 0004 queue as coverage bias.

## Batch notes — batch 03, NC House districts 21-30 (2026-08-24)

**17 rows: 14 for districts 21-30, plus 3 backfills into earlier batches.** Four members seated nothing.

| District | Member | Rows |
|---|---|---|
| 21 | Ya Liu | abortion 2 · redistricting 1 |
| 22 | William D. Brisson | 0 — one primary bill in the session, on corn farming |
| 23 | Shelly Willingham | housing 3 |
| 24 | Dante Pittman | 0 |
| 25 | Allen Chesser | housing 3 |
| 26 | Donna McDowell White | 0 |
| 27 | Rodney D. Pierce | abortion 2 · redistricting 1 · **taxes 1** |
| 28 | Larry C. Strickland | 0 — budget bills only |
| 29 | Vernetta Alston | abortion 2 · redistricting 1 · housing 3 |
| 30 | Marcia Morey | abortion 2 · redistricting 1 · data-centers 1 · campaign-finance 2 |

### 🔴 BACKFILL: fetching a bill's full sponsor list found rows the person-first pass missed

House Bill 509's cosponsor list contains **G. Brown (batch 01)** and **Dahle (batch 02)**, and House
Bill 375's contains **Pike (batch 01)**. All three were missed because those batches were worked
member-by-member without pulling each instrument's complete sponsor list.

**Pull the full sponsor list for every chair-shaped bill, once, and check it against every batch —
including batches already pushed.** The bills that carry most of the coverage so far are H20, H509,
H1189, H1229, H1056, H538, H1072, H1118 and H375.

### The first `taxes` row, and why it is chair 1 and not chair 2

`CLAUDE.md` uses this exact ladder as its warning: a bill establishing direction cannot separate
*significantly raise* (1) from *moderately raise* (2). House Bill 1073 escapes that because it states
a **rate and a destination** — a 7% bracket on income above $1 million, paid into the State Public
School Fund. On top of North Carolina's existing flat rate that more than doubles the tax above the
threshold, which no ordinary reading calls moderate, and the money adds to existing school funding.
Chair 2 does not fit; chair 1 does.

### Conflicts and refusals

- **House Bill 934, the AI Regulatory Reform Act, pins nothing by itself.** Section 1 creates criminal
  and civil liability for deepfakes while Section 2 grants AI developers immunity — "the developer of
  the artificial intelligence product is not liable for any errors". One bill pointing at opposite
  ends of the ladder. Alston is a primary sponsor, so her `ai-regulation` spoke is blank.
  ⚠ **Clark, G. Pierce and Ward are on BOTH H934 and H375** — conflicted, blank them when their
  batches come up. Davis (batch 02) was checked and is on H375 only, so his row stands.
- **House Bill 951** funds childcare for state employees and first responders. That is targeted by
  *occupation*, not by income, and no chair on the childcare ladder names an employer-provided
  facility. Blank for Liu.
- **House Bill 46** constrains future health-benefit mandates procedurally without saying who gets
  covered; every healthcare chair is about coverage. Blank for Chesser.
- **`medicare/aid` is blanked for White**, consistent with Ager and Reeder. She is primary sponsor on
  several Medicaid rate and coverage improvements, but chair 3 reads "improve current programs
  **while controlling costs**" and the cost-control clause is never evidenced. Note that the WI
  Madison wave resolved this differently — it seated state-leg Medicaid expanders at chair 3 on the
  reasoning that chair 2's Medicare clause is unreachable. **This campaign is stricter.** If that is
  the wrong call, the fix is a ladder revision, not a per-row exception, and White, Ager and Reeder
  should all be revisited together.

### 🔴 Editions, resolved: the member list shows the CURRENT title, edition 1 shows the ORIGINAL text

House Bill 437 makes this plain. The member list titles it `Drug-Free Zones/Unauthorized Public
Camping`, but editions 1 **and** 2 are titled "Establish Drug-Free Homeless Service Zones" and contain
no camping provisions at all. So a later edition added them, and **reading edition 1 can understate a
bill**. The same shape explains H565 and H727. Where the later editions still do not show the current
subject, the bill stays unresolved and the spoke stays blank — that is now three bills
(H437, H565, H727) parked for a PDF read rather than guessed.

## Batch notes — batch 04, NC House districts 31-40 (2026-08-24)

**26 rows, and for the first time every member in the batch seated something.** Three times the
previous best, on **four** new source reads instead of twenty-five, because the batch was worked
bill-first: pull each chair-shaped bill's full sponsor list once, then read it across the roster.

| District | Member | Rows |
|---|---|---|
| 31 | Zack Hawkins | redistricting 1 · abortion 2 · campaign-finance 2 · housing 3 |
| 32 | Bryan Cohn | redistricting 1 · housing 3 |
| 33 | Monika Johnson-Hostler | abortion 2 · housing 3 |
| 34 | Tim Longest | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 |
| 35 | Mike Schietzelt | ai-regulation 3 · housing 3 |
| 36 | Julie von Haefen | redistricting 1 · abortion 2 · housing 3 |
| 37 | Erin Paré | **childcare 4** |
| 38 | Abe Jones | redistricting 1 |
| 39 | James Roberson | redistricting 1 · abortion 2 · housing 3 · data-centers 1 |
| 40 | Phil Rubin | redistricting 1 · abortion 2 · housing 3 |

### 🔴 CORRECTION APPLIED IN PROD: Alston was described as a primary sponsor and is not

House Bill 1056's primary sponsor is **Dahle alone**; Alston is a cosponsor. The batch 03 row said
"Alston is a primary sponsor", which is wrong in text a voter reads. The chair is unaffected —
cosponsorship supports chair 3 the same way it does for Ager — so the fix was the sentence, not the
value. Updated in place.

**Root cause:** a member's `IntroducedBills` page was read as though every bill listed were primarily
sponsored. It is not. **Confirm primary sponsorship against the BILL's sponsor list, never against
the member's bill list.** Every other committed row claiming primary sponsorship was audited against
its bill's sponsor list and is correct.

This also means a reasoning-only correction cannot go through `push-nc-stances.mjs`: the value is
unchanged, so the row lands in the `unchanged` bucket and is skipped. It needs a targeted UPDATE.

### `childcare` finally has a chair on the other side

House Bill 412 lowers the lead-teacher requirement to one per two groups, widens who qualifies as a
lead teacher, allows larger toddler groups, deems school buildings compliant for after-school care,
and makes star ratings voluntary so reimbursement no longer depends on them — while leaving subsidy
rates alone. That is chair 4's first clause exactly. Chair 3 needs provider training and facility
grants (absent) and chair 5 needs subsidies gone (contradicted), so chair 4 uniquely fits. Set
against G. Brown's chair 2 on House Bill 316, the axis now has real spread.

### Hawkins is blank on `ai-regulation`, and it took three bills to see why

He is a primary sponsor of House Bill 934 (developer immunity), House Bill 1161 "Omnibus Artificial
Intelligence Protections" **and** House Bill 1177 "Consumer Protection AI Bill of Rights". That is
chair disagreement inside one member's own record. Rubin is blank for a different reason: he is a
cosponsor of House Bill 934 only, and that bill pins nothing by itself.

⚠ **House Bill 1161 and House Bill 1177 are unread.** They may seat `ai-regulation` for members who
are not on House Bill 934. Worth pulling both sponsor lists before the next AI-heavy batch.

## Batch notes — batch 05, NC House districts 41-50 (2026-08-24)

**20 rows across 9 of 10 members, on three new source reads.** The bill index carried the rest.

| District | Member | Rows |
|---|---|---|
| 41 | Maria Cervania | redistricting 1 · housing 3 · data-centers 1 · campaign-finance 2 |
| 42 | Mike Colvin | redistricting 1 |
| 43 | Diane Wheatley | 0 |
| 44 | Charles Smith | housing 3 |
| 45 | Frances Jackson, PhD | redistricting 1 · housing 3 · ai-regulation 3 |
| 46 | Brenden H. Jones | **civil-rights 5** |
| 47 | John L. Lowery | **civil-rights 5** · ai-regulation 3 |
| 48 | Garland E. Pierce | childcare 2 |
| 49 | Cynthia Ball | redistricting 1 · abortion 2 · housing 3 |
| 50 | Renée A. Price | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 |

### 🔴 CORRECTION to batch 02's fifth ladder observation

Batch 02 recorded that `civil-rights` chairs 4 and 5 were "close to unreachable" for a state
legislator, on the strength of House Bill 799 seating nothing. **That was overstated.**

House Bill 171 seats **chair 5** cleanly. It bars DEI programs *and* race-based consideration in
hiring, contracting and admissions, across state agencies, local government, the UNC system,
community colleges and any body receiving public funds — carving out only federal civil rights
compliance, instruction, research and student organisations. Chair 5 reads "eliminate affirmative
action **and all** race-based government programs" and both clauses are evidenced.

So the restrictive side of this axis **is** reachable; it needs a comprehensive bill. H799 simply is
not one. **Chair 4 remains unreachable**, because it is about limiting *federal* enforcement, which
no state legislator can do — but that is one chair, not half a ladder.

The `voting-rights` asymmetry from batch 01 still stands and was not affected by this: no chair on
that ladder names reducing early voting.

**The general lesson: do not call a chair unreachable after one bill fails to reach it.** Two bills
of the same apparent kind can sit on opposite sides of the bar, and the difference is scope, which
only shows up on a read.

### Refusals

- **House Bill 456** (Colvin) regulates surprise ambulance billing. The healthcare ladder is about
  coverage architecture, so billing regulation seats nothing — same call as House Bill 434.
- **House Bill 453** (Wheatley, White) raises Medicaid personal care and private duty nursing rates.
  Still no evidence for chair 3's "while controlling costs" clause, so `medicare/aid` stays blank —
  consistent with Ager, Reeder and White.
- **House Bill 951** (Colvin) funds childcare for state employees and first responders: targeted by
  occupation, not income, and no chair names an employer-provided facility.

## Batch notes — batch 06, NC House districts 51-60 (2026-08-24)

**18 rows across 8 of 10, on three source reads.**

| District | Member | Rows |
|---|---|---|
| 51 | John Sauls | 0 — four primary bills, none touching the 28 topics |
| 52 | Ben T. Moss, Jr. | data-centers 2 |
| 53 | Howard Penny, Jr. | 0 |
| 54 | Robert T. Reives, II | redistricting 1 · abortion 2 · housing 3 |
| 55 | Mark Brody | housing 4 |
| 56 | Allen Buansi | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 · taxes 1 |
| 57 | Tracy Clark | redistricting 1 · abortion 2 · housing 3 |
| 58 | Amos L. Quick, III | redistricting 1 · housing 3 · data-centers 1 |
| 59 | Jerry "Alan" Branson | ai-regulation 3 |
| 60 | Amanda P. Cook | campaign-finance 2 |

**Clark is blank on `ai-regulation` by the conflict rule** — he is on House Bill 375 and House Bill
934. The index caught it without a fetch, which is exactly what it is for.

**Brody's housing 4 needed a negative check, not a positive one.** House Bill 765 is chair 4 only if
the member has no housing appropriation anywhere; his record is building-code and inspection
deregulation throughout, so the chair holds. Same test that separated Winslow (chair 4) from Ager,
Dahle and Bell (chair 3).

## Batch notes — batch 07, NC House districts 61-70 (2026-08-24)

**13 rows across 7 people, one of them a backfill.** Five members seated nothing.

| District | Member | Rows |
|---|---|---|
| 61 | Pricey Harrison | redistricting 1 · abortion 2 · data-centers 1 · campaign-finance 2 · civil-rights 2 · ai-regulation 3 |
| 62 | John M. Blust | ai-regulation 3 |
| 63-65, 68 | Ross, Riddell, Pyrtle, Willis | 0 |
| 66 | Sarah Crawford | redistricting 1 · housing 3 |
| 67 | Cody Huneycutt | ai-regulation 3 |
| 69 | Dean Arp | childcare 4 |
| 70 | Brian Biggs | **homelessness 4** |
| 35 | Mike Schietzelt (backfill) | **homelessness 4** |

Harrison is the campaign's widest single record so far at six rows, all from bills she primarily
sponsored or cosponsored.

### `homelessness` opens, and the chair turns on the enforcement mechanism

House Bill 781 bars local governments from authorising camping or sleeping on public property. A
council may set aside its own land for up to a year, but only after documenting that shelter beds are
insufficient.

- **Chair 5 is excluded** because enforcement is **civil, not criminal** — residents, business owners
  or the Attorney General sue for an injunction. Chair 5 requires criminal penalties.
- **Chair 3 is excluded** because it conditions *enforcement* on beds being available. This bill does
  the reverse: it conditions *permission to allow camping* on beds being insufficient, and provides no
  citation-to-services diversion.
- **Chair 4 fits**: prohibiting encampments on public property, without criminal penalties.

### Refusals

- **House Bill 301** (Willis) is titled `Social Media & AI Safety` on the member list but is
  "Social Media Protections for Minors Under 16" in the text — age verification and account limits
  for under-16s, with nothing about how algorithms work or any AI duty. Blank.
- **House Bill 31** (Ross, Biggs) makes Election Day a state holiday. No chair on the voting-rights
  ladder names a holiday.

### Edition theory confirmed again

Biggs's member list gives House Bill 87's current short title as **"Educational Choice for Children
Act (ECCA)"**, while the edition-1 text read during the pilot was a cell-phone-free education bill.
That is the same pattern as House Bill 437: **the member list shows the current title, edition 1 shows
the original text.** It also means the pilot's dropped `school-vouchers` row was dropped for the right
reason — the vote cited was on the cell-phone text — but H87 in its current form may well be a voucher
bill, and is worth a PDF read alongside H565, H727 and H437.

## Batch notes — batch 08, NC House districts 71-80 (2026-08-24)

**14 rows across 7 people.**

| District | Member | Rows |
|---|---|---|
| 71 | Kanika Brown | redistricting 1 · abortion 2 · housing 3 · campaign-finance 2 |
| 72 | Amber M. Baker | redistricting 1 · abortion 2 · housing 3 · taxes 1 |
| 73 | Jonathan L. Almond | ai-regulation 3 |
| 74 | Jeff Zenger | housing 4 |
| 75 | Donny Lambeth | childcare 4 |
| 76 | Harry Warren | ai-regulation 3 |
| 77, 79, 80 | Howard, Kidwell, Watford | 0 |
| 78 | Neal Jackson | civil-rights 5 · homelessness 4 |

Zenger is blank on `ai-regulation` despite sponsoring two AI-titled bills: he is a primary sponsor of
House Bill 934, which pins nothing, and House Bill 301, whose text is social-media age verification
for under-16s with no AI duty at all.

### 🔴 SEVENTH LADDER DEFECT: `abortion` has no rung for the modal restrictive position

Kidwell and Moss primarily sponsor **House Bill 804, The Human Life Protection Act of 2025**. It bans
abortion with an exception **only** where a physician finds a life-threatening physical condition, and
it criminalises **providers** while stating explicitly that a pregnant person is not subject to
criminal liability.

- **Chair 5 is excluded**: it requires "no exceptions" **and** "criminal penalties for providers **and
  patients**". The bill has an exception and deliberately exempts patients.
- **Chair 4 is excluded**: it reads "only cases involving **rape, incest**, or serious threats to the
  mother's life". The bill permits neither rape nor incest.

Seating chair 4 would publish Kidwell as **more permissive than his own bill**. So the row is blank,
and Kidwell seats nothing this batch.

**This is a real gap, not a research failure.** "Ban with a life-of-the-mother exception only,
providers liable, patients not" is the most common restrictive abortion statute in the United States,
and this ladder has no rung for it — the jump from chair 4 to chair 5 skips over it entirely. Every NC
member sponsoring a bill of that shape will blank on this axis. It belongs in the ADR 0004 queue with
the `medicare/aid`, `same-sex-marriage` and `voting-rights` findings.

## Batch notes — batch 09, NC House districts 81-90 (2026-08-24)

**11 rows: 8 for districts 81-90, plus 3 backfills.** Six members seated nothing — this stretch is
heavy with education, healthcare-technical and local bills.

| District | Member | Rows |
|---|---|---|
| 82 | Brian Echevarria | **religious-freedom 4** |
| 84 | Jeffrey C. McNeely | ai-regulation 3 |
| 85 | Dudley Greene | data-centers 2 |
| 88 | Mary Belk | redistricting 1 · abortion 2 · housing 3 · data-centers 1 · campaign-finance 2 |
| 81, 83, 86, 87, 89, 90 | Potts, Campbell, Blackwell, D. Hall, Setzer, Kiger | 0 |
| 69 | Dean Arp (backfill) | religious-freedom 4 |
| 78 | Neal Jackson (backfill) | religious-freedom 4 |
| 52 | Ben T. Moss, Jr. (backfill) | religious-freedom 4 |

### `religious-freedom` opens on a standard, not a subject

House Bill 776 creates a strict-scrutiny test: the state may not burden religious exercise unless
doing so is essential to a compelling interest and is the least restrictive means. Chair 4 reads
"allow faith-based exemptions from laws that conflict with sincere religious beliefs" — which is what
that standard produces. Chair 5 needs religious organisations to have **complete autonomy in
operations and hiring**, which the bill does not grant, and chair 3 is a balance rather than a tilt
toward exemption.

Note the contrast already in the corpus: Mayfield sits at chair **2** on this axis, from Senate Bill
381's narrow housing-only religious exemption. Same ladder, opposite ends, both from a statute's
operative text.

### Belk is blank on `ai-regulation` even though she is on an AI bill

She cosponsors House Bill 934 only, and that bill pins nothing. The index carried this without a
fetch, as it did for Clark and Rubin.

## Batch notes — batch 10, NC House districts 91-100 (2026-08-24)

**15 rows across 7 people. House districts 1-100 are now swept.**

| District | Member | Rows |
|---|---|---|
| 92 | Terry M. Brown Jr. | redistricting 1 · housing 3 · ai-regulation 3 |
| 94 | Blair Eddins | civil-rights 5 |
| 96 | Jay Adams | ai-regulation 3 |
| 97 | Heather H. Rhyne | childcare 4 |
| 98 | Beth Helfrich | redistricting 1 · abortion 2 |
| 99 | Nasif Majeed | redistricting 1 · abortion 2 |
| 100 | Julia Greenfield | redistricting 1 · abortion 2 · housing 3 · data-centers 1 · campaign-finance 2 |
| 91, 93, 95 | K. Hall, Pickett, Carver | 0 |

**House Bill 306 seats nothing, and the reason is worth keeping.** It is a *local* bill letting
Blowing Rock, Boone and Watauga County build housing **exclusively for their own employees**. It
appropriates nothing, and chair 1's "anyone who needs a home" is contradicted by the employees-only
limit. A local enabling act for one employer is not a position on the state's role in housing.

## Batches 11-12 — NC House districts 101-120 (2026-08-25)

**30 rows. THE HOUSE IS COMPLETE: 78 of 120 members stanced, 187 rows.**

| District | Member | Rows |
|---|---|---|
| 101 | Carolyn G. Logan | redistricting 1 · abortion 2 · housing 3 · childcare 2 · ai-regulation 3 |
| 102 | Becky Carney | redistricting 1 · abortion 2 · housing 3 |
| 103 | Laura Budd | redistricting 1 · abortion 2 |
| 104 | Brandon Lofton | housing 3 |
| 106 | Carla D. Cunningham | abortion 2 · housing 3 |
| 107 | Aisha O. Dew | abortion 2 |
| 112 | Jordan Lopez | redistricting 1 · housing 3 · childcare 2 · data-centers 1 · campaign-finance 2 |
| 115 | Lindsey Prather | redistricting 1 · abortion 2 · housing 3 · data-centers 1 · ai-regulation 3 · taxes 1 |
| 116 | Brian Turner | redistricting 1 · abortion 2 · housing 3 · data-centers 1 |
| 117 | Jennifer Balkcom | homelessness 4 |
| 105, 108-111, 113, 118-120 | Cotham, Torbett, Loftis, Hastings, Scott, Jake Johnson, Pless, Ferguson, Gillespie | 0 |

Prather ties Harrison for the widest record at six rows.

### Cunningham sponsors both a subsidy bill and a deregulation bill — that is chair 3, not a conflict

She is a primary sponsor of House Bill 1072 ($50M in below-market loans at 80% AMI) **and** of House
Bill 765 (pure planning deregulation). Chair 3 is the only chair that accommodates both — chair 4 has
no room for public money. Same reasoning that put Ager at chair 3 on House Bill 1056, which carries
both halves in a single bill. **Two bills pointing at different mechanisms of the same chair is
corroboration; two bills pointing at different chairs is a conflict.**

### Three refusals from this stretch

- **House Bill 306** (Pickett): a local act letting three named jurisdictions build housing only for
  their own employees. Chair 1's "anyone who needs a home" is contradicted by that limit.
- **House Bill 939** (Scott), school chaplains, is squarely on the `religious-freedom` question — the
  ladder asks what role religion should play in public institutions — but **no chair names religion
  *inside* a public institution.** Every chair on that ladder is framed around exemptions and
  anti-discrimination balance. A near-miss worth noting for the season 2 review.
- **House Bill 876** alone (Gillespie) is development review timelines. Zenger's chair 4 rested on
  House Bill 765 plus two others; a single timelines bill does not reach "cut regulations and zoning
  rules so private developers can build more housing".

## ▶️ HOUSE COMPLETE — what remains

| Cohort | Status |
|---|---|
| NC House, 120 seats | ✅ **done — 78 stanced, 187 rows** |
| NC Senate, 50 seats | **next.** 1 stanced (Mayfield, pilot). Needs Senate bill sponsor lists: S467, S381, S439 are already chair-verified. |
| Wave 2b locals, 32 | not started. **Probe Legistar/Granicus per body first** — Durham returned HTTP 500 on the obvious client slug. |
| PDF-read queue | H565, H727, H437, H87 — served text and current title cannot be reconciled. H565 alone would seat `ai-regulation` for four members. |

## Batch notes — Senate 01 (2026-08-25)

**22 rows across 10 senators, from three sponsor lists and no member-by-member reading.** The Senate
map (`nc-senate-member-ids.json`) is saved for all 50.

| District | Senator | Rows |
|---|---|---|
| 5 | Kandie D. Smith | abortion 2 · civil-rights 2 |
| 13 | Lisa Grafstein | civil-rights 2 |
| 15 | Jay J. Chaudhuri | civil-rights 2 |
| 19 | Val Applewhite | abortion 2 · civil-rights 2 · school-vouchers 1 |
| 20 | Natalie S. Murdock | abortion 2 · civil-rights 2 · school-vouchers 1 |
| 22 | Sophia Chitlik | abortion 2 · civil-rights 2 · school-vouchers 1 |
| 27 | Michael Garrett | abortion 2 · school-vouchers 1 |
| 39 | DeAndrea Salvador | abortion 2 · civil-rights 2 |
| 40 | Joyce Waddell | abortion 2 · civil-rights 2 · school-vouchers 1 |
| 41 | Caleb Theodros | abortion 2 · civil-rights 2 |

### 🔴🔴 SESSION vs CURRENT: a sponsor list names who held the seat WHEN THE BILL WAS FILED

Senate Bills 467 and 381 both list **Meyer** as a sponsor. **SD 23 is now held by Jonah Garson.**
Meyer's sponsorship belongs to Meyer, and attributing it to Garson would credit one member with
another's record — the exact error class the Oregon OLIS work spent 188 rows cleaning up.

**Rule, now written into `nc-senate-member-ids.json`: any sponsor surname absent from the current
member map is a FORMER member. Skip it.** This did not arise once across twelve House batches, which
is precisely why it is worth recording — it is invisible until a seat changes hands mid-session.

### What the Senate still needs

These three bills only cover the abortion, civil-rights and school-vouchers axes, and only for
members who signed them. The Senate has no equivalent yet for the bills that carried the House:
redistricting (H20), housing (H1056), data-centers (H1189/H638), campaign-finance (H1229) and
ai-regulation (H375). **Next Senate pass: find and chair-verify the Senate companions**, then read
them across the map the same way.

## Batch notes — Senate 02 (2026-08-25)

**3 rows.** Senate Bill 736, the Foundation Act, seats `housing` 3 for Grafstein (13), Garrett (27)
and Bradley (42).

### Why chair 3 and not chair 2, when the bill has an inclusionary mandate

Senate Bill 736 is the largest housing bill either chamber has produced this session: $50M a year to
the Housing Trust Fund, $3M a year for first-time buyers, $10M a year for community land trusts, $30M
a year in rental assistance, plus ADUs by right and higher density near transit — **and** a
requirement that 20% of units in qualifying developments be affordable at 80% AMI.

That mandate is chair 2's language. But chair 2 reads "**Use rent caps**, require new developments to
include affordable units, and publicly fund new housing", and the bill explicitly contains no rent
control. Chair 3's three clauses — subsidies for affordable projects, first-time buyer assistance,
easier building permits — are **all** evidenced.

Seating chair 2 would publish these senators as supporting rent caps they did not propose. Seating
chair 3 understates the bill slightly but asserts nothing false. **Where one chair is fully evidenced
and an adjacent one contains an unevidenced clause, take the fully evidenced chair** — the risk of a
false statement outweighs the loss of nuance.

⚠ Worth flagging for season 2: chair 2 bundles rent control with inclusionary zoning, which are
distinct policies that often appear apart. A jurisdiction that mandates affordable units without rent
control has no clean rung.

## Batch notes — Senate 03-05 (2026-08-25)

**19 rows. THE SENATE PASS IS COMPLETE: 18 of 50 senators stanced.** Campaign total for the NC
General Assembly: **96 of 170 members, 234 rows.**

New this pass: Mohammed (38), Robinson (28) and Murdock (20) on `housing`; **Mayfield's `housing`,
held since the pilot, is now seated** — Senate Bill 446 is a clean $30M subsidy and pairs with her
Senate Bill 495 ADU mandate exactly as Cunningham's pair did. Six senators take `ai-regulation` 3 from
Senate Bill 735. And the Senate's first Republican rows: Lazzara (6), Overcash (43), Alexander (44)
and Moffitt (48) at `homelessness` 5, Moffitt also at `housing` 4.

### 🔴🔴 THE SPONSOR BLOCK ON THE TEXT PAGE IS NOT RELIABLE — three live rows were wrong

The `/Sessions/.../HTML/` page's sponsor line silently folds cosponsors into what reads as "primary
sponsors". **BillLookUp is authoritative.** This produced three wrong rows, all corrected in prod:

| Row | Claimed | Actually |
|---|---|---|
| Alston / housing (batch 03) | primary sponsor of H1056 | cosponsor — Dahle is sole primary |
| Garrett + Grafstein / housing (S02) | primary sponsors of S736 | cosponsors — Bradley is sole primary |
| Alexander + Overcash / homelessness (S04) | primary sponsors of S724 | cosponsors — Lazzara is sole primary |

The chairs were unaffected every time — cosponsorship supports the same chair — so only the sentence
changed. But it is voter-facing text, and **the third instance also hid a missing row**: reading
S724's real list revealed Moffitt as a cosponsor, which seated him.

**Always read sponsorship from `/BillLookUp/2025/<bill>`, never from the text page.** Now recorded at
the top of `chair-shaped-bills.json`.

### The `homelessness` ladder discriminates on MECHANISM, and both chairs are now occupied

- **House Bill 781 → chair 4.** Civil enforcement only, and a council may allow camping after
  documenting a shelter shortage.
- **Senate Bill 724 → chair 5.** Criminal penalties on a repeat offence (Class 3 misdemeanour), no
  shelter condition at all, and it lets residents sue a city that fails to enforce.

Same direction, different chairs, decided by what the statute actually does. That is the ladder
working as designed.

### Why only 18 of 50, and why that is the honest number

I sampled eleven Republican senators' full bill lists. The chamber's majority files budget,
insurance, local and technical bills; the chair-shaped policy bills are overwhelmingly minority-party
measures. Six Senate title traps were caught and refused: `Safe Camps Act` (youth camps, not
homelessness), `Access to Sports and Extracurriculars for All` (school access, not transgender
eligibility), `Women's Safety and Protection Act` (restrooms, not sports), `Protecting Workers in the
Age of AI Act` (a retraining fund, no AI duty), `Safeguard Fair Elections` (election administration),
`Statewide Child Care Investment Act` (facility grants only).

**The Senate has no counterpart at all** to the House bills that carried redistricting (H20),
campaign-finance (H1229) or data-centers (H1189/H638). That is a fact about what the chamber filed,
not a gap in the search.

### One more compound-chair finding

Senate Bill 457 is straight **automatic voter registration** — but chair 1 reads "automatically
register all eligible citizens **and allow online voting**", and the bill says nothing about online
voting. So `voting-rights` is compound at *both* ends: chair 1 bundles automatic registration with
online voting, chair 2 bundles early voting with no-excuse mail-in. Every near-miss on that ladder
this campaign has been a half-met compound chair.

## Batch notes — local 01, Asheville City Council (2026-08-25)

**20 rows across all 7 members.** First batch of the 32 wave-2b locals. Source map for all four
bodies: `backend/data/stance-research/nc-campaign/local-source-map.md`.

### Three instruments carried the whole council

| Topic | Chair | Instrument |
|---|---|---|
| `data-centers` | 1 | **Ordinance 5238**, 2026-06-23 — one-year moratorium on new data center development. Turner moved, Roney seconded, unanimous, all 7 present. |
| `housing` | 3 | **Resolution No. 26-114**, 2026-06-09 — $9.5M of CDBG-DR to build 126 affordable rental units, 35-year affordability. Roney moved, Mosley seconded, **6-1 with Turner voting no**. Turner is seated instead off **Resolution No. 26-51** (2026-03-10), which she moved, adding affordable rental construction to the Consolidated Plan as a priority need. |
| `economic-development` | 3 | **Resolution No. 26-20**, 2026-01-27 — a $35,000 performance-based grant paid only after investment and hiring, under a city policy carrying a living-wage benchmark. Roney moved, Smith seconded, unanimous. **Turner was absent**, so this is 6 rows, not 7. |

### The seating rule used, stated once

Seat a member when a **standalone, non-consent, recorded vote** on a chair-shaped instrument names
them — as mover, as seconder, or through a stated tally read against the attendance list. Consent-
agenda items seat nobody: they are one block vote on thirty unrelated things.

### 🔴 Four topics were BLANKED with evidence in hand — record why

- **`residential-zoning`.** Ordinance 5196 (ADU by-right adaptive reuse, Smith moved, Mosley
  seconded) satisfies chair 2's *density* clause — accessory units — while **contradicting its
  review clause**, because the whole point of the ordinance is removing Board of Adjustment review.
  It does not reach chair 4's breadth either. Two adjacent chairs, neither clean. The ladder is
  already flagged off-axis in `.planning/todos/2026-08-12-ladder-orientation-and-consumers.md`.
- **`local-immigration`.** Resolution No. 26-97 says the City "shall not utilize these public safety
  tools to participate in enforcement of federal immigration law" — chair 3's text almost verbatim.
  But it was voted **as one bundled motion** with a $1.14M surveillance grant and a budget amendment.
  🔴 **An aye on a bundle does not isolate a clause**, and Roney's lone no was aimed at the
  surveillance half. Same defect shape as a compound chair, arriving through the agenda instead of
  through the ladder.
- **`public-safety-approach`.** The Axon/Fusus contract and the Real Time Intelligence Center are
  police **equipment**. Chair 4 is compound — staffing *and* equipment *and* pay — and the FY27
  budget does not evidence the other two clauses.
- **`transportation-priorities`.** The only instrument is a four-year transit O&M vendor contract
  (Ullman moved, 4-3, Mosley/Smith/Turner no). A vendor choice is not a spending priority, and the
  three no votes were about the vendor.

### 🔴 A minutes document can be an unfilled TEMPLATE

`2025-12-09` is published as approved minutes but reads `Councilwoman ____ moved to`. The clerk
posted the template. It names no one and must be excluded — a scan keyed on member surnames would
otherwise treat the Mayor's boilerplate lines as acts.

### 🔴 Asheville publishes each minutes document TWICE

The ACF `meeting_minutes` field on the agenda-briefing meeting and on the formal meeting point at the
**same** Google Doc, because one document covers both. 21 downloads deduped to **11**. Without a
content-hash dedupe every instrument is double-counted and the corpus looks twice as deep as it is.

### Coverage limit to state plainly

Asheville minutes before ~Dec 2025 are `drive.google.com/file/` PDFs that require a Google sign-in —
confirmed in a real browser, not only with curl. **The readable window is 2025-12-09 → 2026-06-23.**
Twenty rows off eleven meetings is not a full read of this council's record; it is a full read of
the seven months that are public.

## Batch notes — locals 02-04: Durham City, Buncombe, Durham County (2026-08-25)

**23 rows. The locals pass is complete: 43 rows across 21 of the 32 people.**
Durham City 14 · Buncombe 7 · Durham County 2 · (Asheville 20, batch local 01).
`check-stance-sources.mjs` re-run after the write: **745 rows, all four classes at baseline, the four
must-be-0 classes at 0.** The 43 new rows added no violation.

### What seated

| Body | Topic | Chair | Instrument |
|---|---|---|---|
| Durham City ×7 | `data-centers` | 1 | **Ordinance #16683**, 2026-06-15 — extension bringing Durham to a twelve-month moratorium on development approvals for data centers and cryptocurrency mining, under N.C.G.S. 160D-107. Rist moved, Caballero seconded, **7-0**. Baker brought it forward; Williams said on the record that data centers create few jobs for heavy land and resource use. |
| Durham City ×7 | `growth-and-development` | 2 | The **7-0 refusal** of the 4802 Cheek Road annexation, 2026-05-18 — 190 homes on 71 acres **outside the Urban Growth Boundary**, which staff said was inconsistent with the Comprehensive Plan. Recorded discussion names infrastructure capacity for schools, sewer and utility service. |
| Buncombe ×7 | `housing` | 3 | Introduction of the **bond orders for $40M of GO bonds for affordable housing**, 2026-06-02. Moore moved, Wells seconded, unanimous, all seven present. |
| Durham County ×2 | `public-safety-approach` | 2 (Allam), 3 (Jacobs) | **Capital Project Amendment No. 25CPA022**, 2025-01-13 — $16.5M for a Sheriff's Training Facility, passed **3-2**. |

### 🔴 The Durham County pair is the best row in the whole campaign, and it is why cohort passes exist

Allam and Jacobs cast the *same* No vote and land on **different chairs**, because each read a
statement into the record naming a *mechanism*:

- **Allam → 2.** She supports "a full expansion of all the services that HEART provides" and says the
  Sheriff supports only a co-response model "where an armed officer is always responding". That is
  chair 2's *unarmed* responder, named and contrasted.
- **Jacobs → 3.** She describes the expansion as "a mental health professional accompanying CIT
  trained deputies on calls they would be responding to normally", freeing law enforcement to focus on
  violent crime, at a time of constrained revenue. Keep funding, add crisis teams — chair 3.

**Burton, Lee and Valentine are BLANK, and the vote direction is not why.** All three also stated
support for HEART expansion; none named a model. Their Aye also funded $16.5M of new capital, which
contradicts chair 3's "keep current public safety funding", while chair 4's clauses — staffing,
equipment, pay, response times, deterrence — appear nowhere in what they said. Two chairs half-fit, so
neither is seated. ⚠ This leaves the two dissenters seated and the three-vote majority blank. **That
asymmetry is an artefact of who explained themselves, not of who won**, and it should be stated
whenever this batch is quoted.

### 🔴 A fifth ladder defect: `residential-zoning` chair 5 cannot describe how anyone actually ends single-family zoning

On 2025-08-05 Buncombe County adopted the zoning text amendment its own board called "**a significant
milestone in the County's history, ending single family zoning in the County**" (Wells moved, Moore
seconded, unanimous). It could not be seated.

Chair 5 reads "Eliminate single-family-only zoning; **allow any housing type on any lot
communitywide**". Buncombe ended mandatory single-family zoning by allowing **two dwelling units per
lot** in the last district that forbade it. So chair 5's headline clause is met in the county's own
words while its operative clause is not — and two units per lot is precisely chair 2's "modest density
increases (duplexes, accessory units)", whose own qualifier ("strong design review and neighborhood
input") is contradicted, because the amendment *removes* the holdover standards.

This is not a Buncombe quirk. **Every real jurisdiction that has ended single-family-only zoning did it
by allowing 2-4 units, not "any housing type"** — Minneapolis, Oregon HB 2001, California SB 9. As
written, chair 5 is unreachable and chair 2 is contradicted by the same act, so the ladder cannot
describe the single most common zoning reform in the country. → ADR 0004 / season 2 queue, alongside
`medicare/aid`, `same-sex-marriage` and `voting-rights`.

### 🔴 In Durham the MOVER IS A ROLE, so mover and seconder are not evidence

Durham City minutes show the Mayor Pro Tempore moving nearly every general-business item, and a single
pair moving and seconding thirty consecutive consent items at one timestamp. Reading "Council Member X
moved" as a position would have manufactured a stance for whoever held the chair. **In Durham only the
named tally counts** — the opposite of Asheville, where the mover genuinely chose the item. The
seating rule has to be re-derived per body.

### What the Durham County corpus actually is

Legistar has no minutes for this board at all. The county's own site does, and they are excellent —
verbatim statements plus named Ayes and Nays — at
`dconc.gov/Board-of-Commissioners1/Archived-Agendas--Minutes/<YYYY>/<YYYYMMDD>{RS,WS,SS}Minutes.pdf`.
🔴 **An absent document in one system is not an absent document.** But the archive stops after
January 2025: 2024 in full, then exactly three 2025 files, then 404s. The current five commissioners
were seated 2024-12-09, so **the whole current board is readable across four meetings**. Two rows off
four meetings is the honest yield, not a failure of the search.

### The eleven who seated nothing, and why

- **6 administrative and law-enforcement officers** — Sheriff Birkhead and Sheriff Miller, Registers of
  Deeds Davis and Reisinger, Clerks of Superior Court Thompson and Christy. They hold no vote in the
  bodies whose minutes exist, and the 22 local topics ask about policy their offices do not set. This
  is the documented zero the plan predicted; do not force it.
- **Burton, Lee, Valentine** — reasoning above.
- **Buncombe's `residential-zoning`** cost the other two nothing extra; every commissioner seated
  `housing`.

### Yield, measured

**43 rows across 32 people, 21 of whom seated something — 1.3 rows per person, 2.0 per person who
seated anything.** Against the assembly's 1.6 and 2.4. Councils are thinner than legislatures per head
because one instrument seats a whole body at once: **three instruments carried Asheville's seven, two
carried Durham's seven, one carried Buncombe's seven.** The binding constraint is not evidence per
person, it is how many chair-shaped instruments a body voted on inside the readable window.

## PDF-read queue closed (2026-08-25) — 0 new rows, and the blanks were right

H565, H727, H437 and H87 were parked because the text served from
`/Sessions/2025/Bills/House/HTML/` was a different subject from the bill's current title, and the
campaign refused to guess. Reading the **PDF editions** off `/BillLookUp/2025/<bill>` resolves all
four at once, and they are all the same thing.

### 🔴🔴 A BILL'S CURRENT TITLE CAN BELONG TO THE OTHER CHAMBER'S COMMITTEE SUBSTITUTE

Every one of the four was **gutted and replaced in a SENATE committee substitute**, a year or more
after House members filed it. The sponsor list never changes — it still names the original House
filers — so pairing *current title* with *primary sponsors* attributes the Senate's policy to House
members who never filed it.

| Bill | As filed and as it left the House | After the Senate substitute |
|---|---|---|
| **H565** | organ and tissue donation enrolment via the income tax return (v0-v3) | **AI in healthcare billing** — Senate Health Care CS 6/3/26, Senate Judiciary CS 6/23/26 |
| **H727** | modify the laws of marriage and family therapy (v0-v2) | limit Medicaid reimbursement for facility fees — Senate Health Care CS 4/30/26 |
| **H437** | drug-free homeless service zones (v0-v2) | **+ ban unauthorized public camping statewide** — Senate Judiciary CS 6/10/26; **RATIFIED** at v6 |
| **H87** | cell-phone-free education (v0-v3) | Educational Choice for Children Act, a federal scholarship tax credit — Senate Finance CS 7/29/25 |

**H565 was the whole prize and it is refused.** It would have been the campaign's only
`ai-regulation` row, for Reeder (D9), Potts, Shepard (D15) and Huneycutt. What those four actually
filed is `AN ACT TO ALLOW RESIDENT TAXPAYERS TO ENROLL IN THE ORGAN AND TISSUE DONATION PROGRAM VIA
THEIR INCOME TAX RETURN`. Seating them on AI would have been a false statement about four real people
— arrived at through a citation that checks out at every step except the one that matters.

**This also explains the "irreconcilable" HTML.** The `/Sessions/` page was serving an early House
edition while the title tracked the latest Senate edition. Not a data bug — a real gut-and-replace.
🔴 **The `/Sessions/` HTML does not carry every edition; the PDF list on BillLookUp does.** v0 through
v5, v6 or v7 exist for these bills where the HTML offered two.

### The rule this adds

**Sponsorship evidences the bill AS FILED.** Before citing a bill by its current title, check whether
the edition carrying that title is a committee substitute from the *other* chamber. If it is, the
sponsors are evidence for the old subject, not the new one.

### One follow-up worth recording

**H437 is ratified law and bans unauthorized public camping statewide** — that is chair-shaped for
`homelessness` (4 or 5, depending on the enforcement mechanism). It is unreachable from sponsorship,
because the camping ban is Senate committee work. It would be reachable from the **ratification roll
calls**, which this campaign never used. Park it for whenever roll-call evidence enters the pipeline.
